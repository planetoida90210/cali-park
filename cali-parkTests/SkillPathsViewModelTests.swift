//
//  SkillPathsViewModelTests.swift
//  cali-parkTests
//
//  Sprint SK5 — the Skills tab view model and its copy: mapping logs and
//  placement to per-path summaries, the level, per-rung progress, detecting
//  fresh advances between loads, and the criterion/progress formatting shown on
//  ladders. Pure and deterministic: stores are in-memory, no timing.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Copy formatting

struct ProgressionFormatTests {
    @Test func criterionReadsRepsHoldsAndMarkers() {
        #expect(ProgressionFormat.criterion(.setsOfReps(sets: 3, reps: 8)) == "3 × 8")
        #expect(ProgressionFormat.criterion(.setsOfHold(sets: 3, seconds: 20)) == "3 × 20 s")
        #expect(ProgressionFormat.criterion(.setsOfReps(sets: 1, reps: 1)) == "pierwsze czyste")
        #expect(ProgressionFormat.criterion(.setsOfHold(sets: 1, seconds: 5)) == "pierwsze 5 s")
    }

    @Test func bestPairsSetsWithLoggedValue() {
        #expect(ProgressionFormat.best(RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 6)) == "3 × 6")
        #expect(ProgressionFormat.best(RungProgress(criterion: .setsOfHold(sets: 3, seconds: 20), bestValue: 15)) == "3 × 15 s")
        // A single-hold marker shows just the seconds; a single-rep marker is binary.
        #expect(ProgressionFormat.best(RungProgress(criterion: .setsOfHold(sets: 1, seconds: 5), bestValue: 3)) == "3 s")
        #expect(ProgressionFormat.best(RungProgress(criterion: .setsOfReps(sets: 1, reps: 1), bestValue: 1)) == nil)
    }

    @Test func bestIsNilWithoutQualifyingSession() {
        #expect(ProgressionFormat.best(RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 0)) == nil)
    }

    @Test func progressLineJoinsTargetAndBest() {
        let withBest = RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 6)
        #expect(ProgressionFormat.progressLine(withBest) == "3 × 8 — Twoje najlepsze: 3 × 6")

        let noBest = RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 0)
        #expect(ProgressionFormat.progressLine(noBest) == "3 × 8")
    }

    @Test func equipmentFallsBackToBodyweight() {
        #expect(ProgressionFormat.equipment([]) == "Masa ciała")
        #expect(ProgressionFormat.equipment(["Pull-up bar"]) == "Pull-up bar")
        #expect(ProgressionFormat.equipment(["Pull-up bar", "Rings"]) == "Pull-up bar · Rings")
    }

    @Test func spokenCriterionSpellsUnitsForVoiceOver() {
        #expect(ProgressionFormat.spokenCriterion(.setsOfReps(sets: 3, reps: 8)) == "3 serie po 8 powtórzeń")
        #expect(ProgressionFormat.spokenCriterion(.setsOfHold(sets: 3, seconds: 20)) == "3 serie po 20 sekund")
    }
}

// MARK: - Fresh advance detection

@MainActor
struct SkillPathAdvanceTests {
    private func summary(_ id: ProgressionPathID, conquered: Int) -> SkillPathSummary {
        let path = ProgressionCatalog.path(withID: id)!
        let current = min(conquered, path.steps.count - 1)
        let state = PathState(
            pathID: id,
            rungCount: path.steps.count,
            currentRungIndex: current,
            conqueredRungCount: conquered,
            currentProgress: RungProgress(criterion: path.steps[current].criterion, bestValue: 0)
        )
        return SkillPathSummary(path: path, state: state)
    }

    @Test func firstLoadCelebratesNothing() {
        let advances = SkillPathsViewModel.advances(from: [], to: [summary(.pullUp, conquered: 3)])
        #expect(advances.isEmpty)
    }

    @Test func growingConqueredCountIsAnAdvance() {
        let advances = SkillPathsViewModel.advances(
            from: [summary(.pullUp, conquered: 2), summary(.dip, conquered: 1)],
            to: [summary(.pullUp, conquered: 3), summary(.dip, conquered: 1)]
        )
        #expect(advances == [.pullUp])
    }

    @Test func unchangedStateIsNotAnAdvance() {
        let advances = SkillPathsViewModel.advances(
            from: [summary(.pullUp, conquered: 3)],
            to: [summary(.pullUp, conquered: 3)]
        )
        #expect(advances.isEmpty)
    }
}

// MARK: - View model mapping

@MainActor
struct SkillPathsViewModelTests {
    private func makeViewModel(logs: [WorkoutLogEntry] = [],
                               placement: SkillPlacement? = nil) -> SkillPathsViewModel {
        SkillPathsViewModel(
            logStore: InMemoryWorkoutLogStore(initial: logs),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            progressStore: InMemorySkillProgressStore()
        )
    }

    @Test func freshAthleteStartsAtTheBottomOfEveryPath() {
        let viewModel = makeViewModel()

        #expect(viewModel.hasPlacement == false)
        #expect(viewModel.level.level == 1)
        #expect(viewModel.summaries.count == ProgressionCatalog.all.count)
        #expect(viewModel.summaries.allSatisfy { $0.state.currentRungIndex == 0 })
        #expect(viewModel.summaries.allSatisfy { $0.state.conqueredRungCount == 0 })
    }

    @Test func placementSetsTheCurrentRung() {
        // Declaring rung 4 (full pull-ups) conquers everything below it.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 4])
        let viewModel = makeViewModel(placement: placement)

        #expect(viewModel.hasPlacement)
        let pullUp = try! #require(viewModel.summary(for: .pullUp))
        #expect(pullUp.state.currentRungIndex == 4)
        #expect(pullUp.state.conqueredRungCount == 4)
        #expect(pullUp.currentStep.exerciseID == ExerciseCatalog.pullUpsID)
    }

    @Test func logsAdvanceThePathAndScoreTheRung() {
        let logs = [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
            )
        ]
        let viewModel = makeViewModel(logs: logs)

        let pullUp = try! #require(viewModel.summary(for: .pullUp))
        // Conquering full pull-ups (index 4) puts the athlete on L-pull-ups (5).
        #expect(pullUp.state.currentRungIndex == 5)
        #expect(pullUp.currentStep.exerciseID == ExerciseCatalog.lPullUpsID)

        // Volume plus five conquered rungs lifts the athlete past level 1.
        #expect(viewModel.level.level == 2)
    }

    @Test func rungProgressScoresAnyRungFromLogs() {
        let logs = [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
            )
        ]
        let viewModel = makeViewModel(logs: logs)
        let path = ProgressionCatalog.path(withID: .pullUp)!
        let pullUpStep = try! #require(path.steps.first { $0.exerciseID == ExerciseCatalog.pullUpsID })

        let progress = viewModel.rungProgress(for: pullUpStep)
        #expect(progress.bestValue == 6)
        #expect(progress.isMet == false)
    }

    @Test func reloadAfterTrainingReportsAFreshAdvance() throws {
        let store = InMemoryWorkoutLogStore()
        let viewModel = SkillPathsViewModel(
            logStore: store,
            placementStore: InMemorySkillPlacementStore(),
            progressStore: InMemorySkillProgressStore()
        )
        #expect(viewModel.recentlyAdvancedPaths.isEmpty)

        try store.append(
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
            )
        )
        viewModel.load()

        #expect(viewModel.recentlyAdvancedPaths.contains(.pullUp))
    }
}
