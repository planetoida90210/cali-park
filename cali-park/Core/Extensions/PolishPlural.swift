import Foundation

// MARK: - PolishPlural
/// Polish plural forms without pulling in localization infrastructure yet:
/// 1 seria, 2–4 serie, 5+ serii — with the 12–14 teens exception
/// (12 serii, but 22 serie).
enum PolishPlural {
    /// Picks the right form for `count`:
    /// - `one` for exactly 1,
    /// - `few` for counts ending in 2–4 (except 12–14),
    /// - `many` for everything else (including 0).
    static func form(for count: Int, one: String, few: String, many: String) -> String {
        if count == 1 { return one }
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        if (2...4).contains(lastDigit) && !(12...14).contains(lastTwoDigits) {
            return few
        }
        return many
    }

    /// "1 seria", "3 serie", "5 serii".
    static func sets(_ count: Int) -> String {
        "\(count) \(form(for: count, one: "seria", few: "serie", many: "serii"))"
    }

    /// "1 powtórzenie", "3 powtórzenia", "5 powtórzeń".
    static func reps(_ count: Int) -> String {
        "\(count) \(form(for: count, one: "powtórzenie", few: "powtórzenia", many: "powtórzeń"))"
    }

    /// "1 dzień", "3 dni", "5 dni".
    static func days(_ count: Int) -> String {
        "\(count) \(form(for: count, one: "dzień", few: "dni", many: "dni"))"
    }

    /// "1 podciągnięcie", "3 podciągnięcia", "5 podciągnięć".
    static func pullUps(_ count: Int) -> String {
        "\(count) \(form(for: count, one: "podciągnięcie", few: "podciągnięcia", many: "podciągnięć"))"
    }

    /// "1 ćwiczenie", "3 ćwiczenia", "5 ćwiczeń".
    static func exercises(_ count: Int) -> String {
        "\(count) \(form(for: count, one: "ćwiczenie", few: "ćwiczenia", many: "ćwiczeń"))"
    }
}
