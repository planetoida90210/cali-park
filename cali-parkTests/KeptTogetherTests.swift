//
//  KeptTogetherTests.swift
//  cali-parkTests
//
//  No line breaks inside number ranges, before "min" or after "r/".
//

import Testing
@testable import cali_park

struct KeptTogetherTests {
    private let joiner = String(String.wordJoiner)
    private let noBreakSpace = String(String.noBreakSpace)

    @Test
    func rangeAndUnitStayOnOneLine() {
        #expect("ok. 45–60 min".keptTogether == "ok. 45–\(joiner)60\(noBreakSpace)min")
    }

    @Test
    func subredditStaysOnOneLine() {
        #expect("wiki r/bodyweightfitness.".keptTogether == "wiki r/\(joiner)bodyweightfitness.")
    }

    @Test
    func otherTextIsUntouched() {
        let text = "Pon – Śr, 3 serie, a/b, minuta"
        #expect(text.keptTogether == text)
    }

    @Test
    func everyProgramCardKeepsItsRangesTogether() {
        for program in ProgramCatalog.all {
            let card = "\(program.frequency) · \(program.sessionLength) \(program.creditLine)".keptTogether
            #expect(!card.contains("r/b"))
            #expect(!card.contains(" min"))
        }
    }
}
