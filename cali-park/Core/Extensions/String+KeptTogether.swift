import Foundation

// MARK: - Kept-together typography
nonisolated extension String {
    /// The text with line breaks ruled out where they read badly in Polish UI
    /// copy: inside a number range ("45–60"), between a number and its unit
    /// ("60 min", "90 s"), around a multiplication sign between numbers
    /// ("3 × 8"), after "ok." ("ok. 45") and after "r/"
    /// ("r/bodyweightfitness"). Uses invisible joiners and no-break spaces, so
    /// what is read out and copied stays the same text.
    var keptTogether: String {
        let characters = Array(self)
        var result = ""
        result.reserveCapacity(utf8.count)

        for index in characters.indices {
            let character = characters[index]
            let previous = index > characters.startIndex ? characters[index - 1] : nil
            let next = index + 1 < characters.endIndex ? characters[index + 1] : nil

            if character == " ", Self.bindsSpace(at: index, in: characters) {
                result.append(Self.noBreakSpace)
                continue
            }

            result.append(character)

            let joinsRange = character == "–" && previous?.isNumber == true && next?.isNumber == true
            let joinsSubreddit = character == "/" && previous == "r" && next?.isLetter == true
            if joinsRange || joinsSubreddit {
                result.append(Self.wordJoiner)
            }
        }
        return result
    }

    /// Whether the space at `index` must not break the line: it sits between
    /// a number and a unit ("min", or "s" as a whole word), between a number
    /// and "×" (on either side), or after "ok.".
    private static func bindsSpace(at index: Int, in characters: [Character]) -> Bool {
        let previous = index > 0 ? characters[index - 1] : nil
        let next = index + 1 < characters.count ? characters[index + 1] : nil
        let rest = characters[(index + 1)...]

        let afterNumber = previous?.isNumber == true
        let beforeUnit = rest.starts(with: "min") || startsWithSecondsUnit(rest)
        let aroundTimes = (afterNumber && next == "×")
            || (previous == "×" && next?.isNumber == true)
        let afterAbbreviation = index >= 3 && characters[(index - 3)..<index].elementsEqual("ok.")
        return (afterNumber && beforeUnit) || aroundTimes || afterAbbreviation
    }

    /// Whether `rest` starts with the seconds symbol "s" as a whole word, not
    /// with a word like "serie".
    private static func startsWithSecondsUnit(_ rest: ArraySlice<Character>) -> Bool {
        guard rest.first == "s" else { return false }
        let after = rest.dropFirst().first
        return after.map { !$0.isLetter } ?? true
    }

    /// U+2060: no line break on either side.
    static let wordJoiner: Character = "\u{2060}"
    /// U+00A0: a space that never breaks.
    static let noBreakSpace: Character = "\u{00A0}"
}
