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
}
