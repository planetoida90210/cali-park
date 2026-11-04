import Foundation
import Testing
@testable import cali_park

// MARK: - String Catalog

/// The app has a Polish String Catalog (`Localizable.xcstrings`). Polish is
/// the source language and the only one, so the catalog compiles to no
/// tables yet and every lookup must return the Polish source text, with its
/// arguments filled in exactly as plain string interpolation would.
@Suite("String Catalog")
struct StringCatalogTests {
    @Test("Polish is the bundle's development language")
    func polishIsTheDevelopmentLanguage() {
        #expect(Bundle.main.developmentLocalization == "pl")
    }

    @Test("A catalog key resolves to its Polish source text")
    func plainKeyResolvesToSource() {
        #expect(String(localized: "Cel tygodniowy") == "Cel tygodniowy")
        #expect(String(localized: "Brak zaplanowanych treningów") == "Brak zaplanowanych treningów")
    }

    @Test("Interpolated arguments render like plain interpolation", arguments: [0, 7, 12, 1_280])
    func interpolationMatchesPlainString(count: Int) {
        let name = "Fundamenty"
        #expect(String(localized: "Poziom \(count)") == "Poziom \(count)")
        #expect(String(localized: "\(name): pozycja \(count) z \(count + 1)") == "\(name): pozycja \(count) z \(count + 1)")
    }

    @Test("Formatters that went through the catalog keep their exact text")
    func formatterOutputIsUnchanged() {
        #expect(WeeklyGoalFormat.streak(3) == "Seria: 3 tygodnie")
        #expect(WeeklyGoalFormat.streak(5) == "Seria: 5 tygodni")
    }
}
