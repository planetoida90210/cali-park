//
//  KeptTogetherTests.swift
//  cali-parkTests
//
//  No line breaks inside number ranges, between a number and its unit or
//  "×", or after "r/".
//

import Testing

@testable import cali_park

struct KeptTogetherTests {
    private let joiner = String(String.wordJoiner)
    private let noBreakSpace = String(String.noBreakSpace)

    @Test
    func rangeAndUnitStayOnOneLine() {
        #expect("ok. 45–60 min".keptTogether == "ok.\(noBreakSpace)45–\(joiner)60\(noBreakSpace)min")
    }

    /// Row 15 of the second visual pass: "przerwa 90" / "s" at AX3.
    @Test
    func secondsAndTimesStayWithTheirNumbers() {
        #expect("przerwa 90 s".keptTogether == "przerwa 90\(noBreakSpace)s")
        #expect("3 × 5–8".keptTogether == "3\(noBreakSpace)×\(noBreakSpace)5–\(joiner)8")
        #expect("3 serie, 5 sekund, × a".keptTogether == "3 serie, 5 sekund, × a")
    }

    @Test
    func measuresNeverWrapFromTheirUnits() {
        #expect(MeasureFormat.seconds(90) == "90\(noBreakSpace)s")
        #expect(MeasureFormat.sets(3, of: 20, .seconds) == "3\(noBreakSpace)×\(noBreakSpace)20\(noBreakSpace)s")
        #expect(
            ProgramFormat.restSummary(for: PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID, restSeconds: 90))
                == "przerwa 90\(noBreakSpace)s")
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
            #expect(card.contains("r/b") == false)
            #expect(card.contains(" min") == false)
        }
    }

    @Test
    func everyAboutSourceKeepsItsSubredditTogether() {
        for source in AboutContent.ladderSources + AboutContent.programSources {
            #expect(source.displayName.contains("r/b") == false, "\(source.name)")
        }
    }
}
