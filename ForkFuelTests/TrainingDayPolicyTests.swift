import XCTest
@testable import ForkFuel

final class TrainingDayPolicyTests: XCTestCase {
    func testSnackRemapsToMiddayWhenPlanningAhead() {
        let policy = TrainingDayPolicy()
        XCTAssertEqual(policy.slotForPlanning(.topUp, plansAhead: true), .refuel)
        XCTAssertEqual(policy.slotForPlanning(.topUp, plansAhead: false), .topUp)
        XCTAssertEqual(policy.slotForPlanning(.preFuel, plansAhead: true), .preFuel)
    }

    func testTargetsFollowKind() {
        let policy = TrainingDayPolicy()
        let picked = policy.targets(kind: .training, training: .trainingDefault, rest: .restDefault)
        XCTAssertEqual(picked.energyKcal, FuelMacroTargets.trainingDefault.energyKcal)
        let rest = policy.targets(kind: .rest, training: .trainingDefault, rest: .restDefault)
        XCTAssertEqual(rest.energyKcal, FuelMacroTargets.restDefault.energyKcal)
    }

    func testWeekendDefaultsToRest() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 23)) ?? Date()
        let monday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 24)) ?? Date()
        let policy = TrainingDayPolicy()
        XCTAssertEqual(policy.inferredKind(for: sunday, calendar: calendar), .rest)
        XCTAssertEqual(policy.inferredKind(for: monday, calendar: calendar), .training)
    }
}
