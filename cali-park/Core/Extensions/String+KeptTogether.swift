import Foundation

// MARK: - Kept-together typography
nonisolated extension String {
    /// The text with line breaks ruled out where they read badly in Polish UI
    /// copy: inside a number range ("45–60"), between a number and "min"
    /// ("60 min"), after "ok." ("ok. 45") and after "r/" ("r/bodyweightfitness"). Uses invisible
    /// joiners, so what is read out and copied stays the same text.
    var keptTogether: String {
        let characters = Array(self)
        var result = ""
        result.reserveCapacity(utf8.count)

        for index in characters.indices {
            let character = characters[index]
            let previous = index > characters.startIndex ? characters[index - 1] : nil
            let next = index + 1 < characters.endIndex ? characters[index + 1] : nil

            let afterNumberBeforeMin = previous?.isNumber == true && characters[(index + 1)...].starts(with: "min")
            let afterAbbreviation = index >= 3 && characters[(index - 3)..<index].elementsEqual("ok.")
            if character == " ", afterNumberBeforeMin || afterAbbreviation {
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

    /// U+2060: no line break on either side.
    static let wordJoiner: Character = "\u{2060}"
    /// U+00A0: a space that never breaks.
    static let noBreakSpace: Character = "\u{00A0}"
}
