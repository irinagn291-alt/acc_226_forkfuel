import Foundation

/// Public citations for starting targets and food figures. Guideline 1.4.1 requires tappable source links.
enum FuelCitationCatalog {
    struct Entry: Identifiable, Equatable, Sendable {
        let id: String
        let title: String
        let detail: String
        let url: URL

        init(title: String, detail: String, address: String) {
            self.id = address
            self.title = title
            self.detail = detail
            guard let parsed = URL(string: address) else {
                fatalError("Citation address must be a valid URL")
            }
            self.url = parsed
        }
    }

    static let entries: [Entry] = [
        Entry(
            title: "Dietary Guidelines for Americans",
            detail: "Adult energy ranges that inform the Rest 2,100 kcal and Training 2,800 kcal starting budgets.",
            address: "https://www.dietaryguidelines.gov"
        ),
        Entry(
            title: "NIH Office of Dietary Supplements — DRI / AMDR",
            detail: "Carbohydrate 45–65% and fat 20–35% of energy. Rest 220 g / 65 g and Training 300 g / 80 g sit in those bands.",
            address: "https://ods.od.nih.gov/HealthInformation/Dietary_Reference_Intakes.aspx"
        ),
        Entry(
            title: "ISSN Position Stand: Protein and Exercise",
            detail: "1.4–2.0 g protein per kg for training athletes. 140 g Rest and 180 g Training match a typical 80–90 kg athlete.",
            address: "https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0177-8"
        ),
        Entry(
            title: "ACSM Nutrition and Athletic Performance",
            detail: "Higher energy and carbohydrate on training days; lower on recovery days.",
            address: "https://journals.lww.com/acsm-msse/fulltext/2016/03000/nutrition_and_athletic_performance.25.aspx"
        ),
        Entry(
            title: "WHO fact sheet: Healthy diet",
            detail: "Population guidance on energy balance and limiting free sugars and saturated fat.",
            address: "https://www.who.int/news-room/fact-sheets/detail/healthy-diet"
        ),
        Entry(
            title: "Open Food Facts",
            detail: "Per-product energy and macros shown in the catalog. Public, user-contributed database.",
            address: "https://world.openfoodfacts.org"
        ),
        Entry(
            title: "FDA Nutrition Facts label",
            detail: "How packaged-food energy and macronutrient values are defined on labels.",
            address: "https://www.fda.gov/food/nutrition-facts-label/how-understand-and-use-nutrition-facts-label"
        )
    ]
}
