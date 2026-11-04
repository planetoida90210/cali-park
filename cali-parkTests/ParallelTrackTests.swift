//
//  ParallelTrackTests.swift
//  cali-parkTests
//
//  Audit A-3: parallel-track rungs (band pull-ups, step-ups) are options,
//  never the mandatory next step. The current rung skips them; logging one
//  still counts for conquest, XP and celebrations as before.
//

import Foundation
import Testing

@testable import cali_park

@Suite("Parallel-track rungs are never the mandatory next step (A-3)")
struct ParallelTrackTests {
    private typealias E = ExerciseCatalog

    /// 2026-10-01T07:30:00Z
    private static let day = Date(timeIntervalSince1970: 1_759_303_800)

    private static func reps(_ exerciseID: UUID, _ counts: Int...) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: exerciseID, date: day, sets: counts.map { LoggedSet(reps: $0) })
    }

    private static func state(
        _ pathID: ProgressionPathID,
        logs: [WorkoutLogEntry],
        placement: SkillPlacement? = nil
    ) throws -> (ProgressionPath, PathState) {
        let path = try #require(ProgressionCatalog.path(withID: pathID))
        return (path, ProgressionEngine.pathState(for: path, logs: logs, placement: placement))
    }

    private static func index(of exerciseID: UUID, in path: ProgressionPath) throws -> Int {
        try #require(path.steps.firstIndex { $0.exerciseID == exerciseID })
    }

    @Test func afterNegativesTheCurrentRungIsFullPullUps() throws {
        let (path, state) = try Self.state(.pullUp, logs: [Self.reps(E.negativePullUpsID, 5, 5, 5)])

        #expect(path.steps[state.currentRungIndex].exerciseID == E.pullUpsID)
        // The band rung is skipped, not conquered: it stays an open option.
        #expect(state.isConquered(rungAt: try Self.index(of: E.bandPullUpsID, in: path)) == false)
        #expect(state.isConquered(rungAt: try Self.index(of: E.negativePullUpsID, in: path)))
    }

    @Test func aZeroPullUpPlacementTrainingNegativesNeverLandsOnTheBand() throws {
        // "0" pull-ups declares negatives; the athlete then logs 3 × 5 of them.
        let placement = PlacementCalibration.placement(repAnswers: [.pullUp: .none], masteredSkills: [], ownsBand: false)
        let (before, beforeState) = try Self.state(.pullUp, logs: [], placement: placement)
        #expect(before.steps[beforeState.currentRungIndex].exerciseID == E.negativePullUpsID)

        let (after, afterState) = try Self.state(.pullUp, logs: [Self.reps(E.negativePullUpsID, 5, 5, 5)], placement: placement)
        #expect(after.steps[afterState.currentRungIndex].exerciseID == E.pullUpsID)
    }

    @Test func afterBulgarianSplitSquatsTheCurrentRungIsTheAssistedPistol() throws {
        let (path, state) = try Self.state(.legs, logs: [Self.reps(E.bulgarianSplitSquatID, 8, 8, 8)])

        #expect(path.steps[state.currentRungIndex].exerciseID == E.assistedPistolSquatsID)
        #expect(state.isConquered(rungAt: try Self.index(of: E.stepUpsID, in: path)) == false)
    }

    @Test func aDeclarationOnAParallelRungStartsOnTheNextMainLineRung() throws {
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: E.bandPullUpsID])
        let (path, state) = try Self.state(.pullUp, logs: [], placement: placement)
        #expect(path.steps[state.currentRungIndex].exerciseID == E.pullUpsID)
    }

    /// Logging a parallel rung counts as it always did: it conquers itself and
    /// everything below, and the conquered rungs earn XP.
    @Test func loggingTheBandStillConquersAndEarnsXP() throws {
        let logs = [Self.reps(E.bandPullUpsID, 8, 8, 8)]
        let (path, state) = try Self.state(.pullUp, logs: logs)
        let bandRung = try Self.index(of: E.bandPullUpsID, in: path)

        #expect(state.conqueredRungCount == bandRung + 1)
        #expect(path.steps[state.currentRungIndex].exerciseID == E.pullUpsID)
        // 24 reps × 10 XP + 5 conquered rungs × 100 XP.
        #expect(ProgressionEngine.experiencePoints(for: logs) == 240 + (bandRung + 1) * ProgressionEngine.xpPerConqueredRung)
    }

    @Test func loggingTheBandStillCelebratesIt() {
        let evaluation = RewardEvaluator.evaluate(
            logs: [Self.reps(E.bandPullUpsID, 8, 8, 8)],
            placement: nil,
            celebrated: SkillProgress(celebratedRungs: [], celebratedLevel: 1)
        )
        #expect(evaluation.pendingEvents.contains(.rungConquered(RungReference(pathID: .pullUp, stepID: E.bandPullUpsID))))
    }

    @Test func theHintNamesTheNextMainLineRungNotTheBand() throws {
        // On negatives with 3 × 3 of the 3 × 5 logged.
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: E.negativePullUpsID])
        let hint = try #require(
            ProgressionEngine.mostActionableHint(
                logs: [Self.reps(E.negativePullUpsID, 3, 3, 3)],
                placement: placement
            ))
        let line = try #require(ProgressionFormat.hintLine(hint))
        let pullUps = try #require(E.exercise(withID: E.pullUpsID)?.name)
        #expect(line.hasSuffix("następny szczebel: \(pullUps)"))
    }
}
