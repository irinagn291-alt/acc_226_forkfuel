import Foundation
import ComposableArchitecture

/// Network seam for Open Food Facts. Injected through `@Dependency` / `DependencyKey`.
struct NutritionGateway: Sendable {
    var searchFuel: @Sendable (_ terms: String) async throws -> [FuelProductSnapshot]
    var fetchProduct: @Sendable (_ code: String) async throws -> FuelProductSnapshot
}

enum NutritionGatewayKey: DependencyKey {
    static let liveValue = NutritionGateway(
        searchFuel: { try await OpenFoodFactsClient.search(terms: $0) },
        fetchProduct: { try await OpenFoodFactsClient.fetchProduct(code: $0) }
    )

    static let testValue = NutritionGateway(
        searchFuel: { _ in [] },
        fetchProduct: { _ in throw NutritionFailure.notFound }
    )
}

extension DependencyValues {
    var nutritionGateway: NutritionGateway {
        get { self[NutritionGatewayKey.self] }
        set { self[NutritionGatewayKey.self] = newValue }
    }
}

/// Owns both Open Food Facts endpoints. User-Agent is set on every request.
enum OpenFoodFactsClient {
    static let userAgent = "ForkFuel/1.0 (iOS; +https://forkfuel.pro)"
    static let pageSize = 12
    static let fieldList = "code,product_name,generic_name,brands,image_front_small_url,nutriments"

    static func search(terms: String) async throws -> [FuelProductSnapshot] {
        try Task.checkCancellation()
        let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
        let shelf = FuelShelfCatalog.matches(terms: trimmed)
        do {
            let remote = try await performSearch(terms: trimmed)
            return FuelShelfCatalog.merge(remote: remote, local: shelf)
        } catch is CancellationError {
            throw NutritionFailure.cancelled
        } catch {
            if shelf.isEmpty {
                throw mapped(error)
            }
            return shelf
        }
    }

    static func fetchProduct(code: String) async throws -> FuelProductSnapshot {
        try Task.checkCancellation()
        var request = URLRequest(url: try productURL(code: code), timeoutInterval: 15)
        applyIdentity(&request)
        let data = try await data(for: request)
        do {
            let envelope = try JSONDecoder().decode(OpenFoodFactsProductEnvelopeDTO.self, from: data)
            if envelope.status == 0 {
                throw NutritionFailure.notFound
            }
            guard let product = envelope.product?.mapped(fallbackCode: code, refreshedAt: Date()) else {
                throw NutritionFailure.notFound
            }
            return product
        } catch let failure as NutritionFailure {
            throw failure
        } catch is CancellationError {
            throw NutritionFailure.cancelled
        } catch {
            throw NutritionFailure.decoding
        }
    }

    private static func performSearch(terms: String) async throws -> [FuelProductSnapshot] {
        var request = URLRequest(url: try searchURL(terms: terms), timeoutInterval: 15)
        applyIdentity(&request)
        let data = try await data(for: request)
        do {
            let decoded = try JSONDecoder().decode(OpenFoodFactsSearchDTO.self, from: data)
            let now = Date()
            return (decoded.products ?? []).compactMap { $0.mapped(fallbackCode: "", refreshedAt: now) }
                .filter(\.hasUsableName)
        } catch is CancellationError {
            throw NutritionFailure.cancelled
        } catch {
            throw NutritionFailure.decoding
        }
    }

    private static func searchURL(terms: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "world.openfoodfacts.org"
        components.path = "/api/v2/search"
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: terms),
            URLQueryItem(name: "fields", value: fieldList),
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
        guard let url = components.url else { throw NutritionFailure.transport }
        return url
    }

    private static func productURL(code: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "world.openfoodfacts.org"
        components.path = "/api/v2/product/\(code).json"
        guard let url = components.url else { throw NutritionFailure.transport }
        return url
    }

    private static func applyIdentity(_ request: inout URLRequest) {
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private static func data(for request: URLRequest) async throws -> Data {
        do {
            return try await execute(request)
        } catch let failure as NutritionFailure {
            throw failure
        } catch {
            if isTransient(error) {
                return try await execute(request)
            }
            throw mapped(error)
        }
    }

    private static func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 {
                throw NutritionFailure.notFound
            }
            if http.statusCode >= 400 {
                throw NutritionFailure.transport
            }
        }
        return data
    }

    private static func isTransient(_ error: Error) -> Bool {
        if error is NutritionFailure { return false }
        let urlError = error as NSError
        return urlError.domain == NSURLErrorDomain
    }

    private static func mapped(_ error: Error) -> NutritionFailure {
        if let failure = error as? NutritionFailure { return failure }
        if error is CancellationError { return .cancelled }
        return .transport
    }

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
        return URLSession(configuration: configuration)
    }()
}
