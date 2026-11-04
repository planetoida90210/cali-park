//
//  SkillPathsViewModelTests.swift
//  cali-parkTests
//
//  The Skills tab view model and its copy: mapping logs and
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
        #expect(MeasureFormat.criterion(.setsOfReps(sets: 3, reps: 8)) == "3 × 8")
        #expect(MeasureFormat.criterion(.setsOfHold(sets: 3, seconds: 20)) == "3 × 20 s")
        #expect(MeasureFormat.criterion(.setsOfReps(sets: 1, reps: 1)) == "pierwsze czyste")
        #expect(MeasureFormat.criterion(.setsOfHold(sets: 1, seconds: 5)) == "pierwsze 5 s")
    }

    /// A-13: after "do" the mastery markers take the genitive.
    @Test func criterionGoalPutsMarkersInTheGenitive() {
        #expect(MeasureFormat.criterionGoal(.setsOfReps(sets: 3, reps: 8)) == "3 × 8")
        #expect(MeasureFormat.criterionGoal(.setsOfHold(sets: 3, seconds: 20)) == "3 × 20 s")
        #expect(MeasureFormat.criterionGoal(.setsOfReps(sets: 1, reps: 1)) == "pierwszego czystego")
        #expect(MeasureFormat.criterionGoal(.setsOfHold(sets: 1, seconds: 5)) == "pierwszych 5 s")
    }

    @Test func hintLineForTheTopHoldRungIsGrammatical() throws {
        let path = try #require(ProgressionCatalog.path(withID: .frontLever))
        let top = path.steps.count - 1
        let hint = ProgressionHint(
            pathID: .frontLever,
            currentRungIndex: top,
            progress: RungProgress(criterion: path.steps[top].criterion, bestValue: 3)
        )
        let line = try #require(ProgressionFormat.hintLine(hint))
        #expect(line.hasPrefix("Jeszcze 2 s do pierwszych 5 s — "))
    }

    @Test func bestPairsSetsWithLoggedValue() {
        #expect(MeasureFormat.best(RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 6)) == "3 × 6")
        #expect(MeasureFormat.best(RungProgress(criterion: .setsOfHold(sets: 3, seconds: 20), bestValue: 15)) == "3 × 15 s")
        // A single-hold marker shows just the seconds; a single-rep marker is binary.
        #expect(MeasureFormat.best(RungProgress(criterion: .setsOfHold(sets: 1, seconds: 5), bestValue: 3)) == "3 s")
        #expect(MeasureFormat.best(RungProgress(criterion: .setsOfReps(sets: 1, reps: 1), bestValue: 1)) == nil)
    }

    @Test func bestIsNilWithoutQualifyingSession() {
        #expect(MeasureFormat.best(RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 0)) == nil)
    }

    @Test func progressLineJoinsTargetAndBest() {
        let withBest = RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 6)
        #expect(MeasureFormat.progressLine(withBest) == "3 × 8 — Twoje najlepsze: 3 × 6")

        let noBest = RungProgress(criterion: .setsOfReps(sets: 3, reps: 8), bestValue: 0)
        #expect(MeasureFormat.progressLine(noBest) == "3 × 8")
    }

    @Test func equipmentFallsBackToBodyweight() {
        #expect(ProgressionFormat.equipment([]) == "Masa ciała")
        #expect(ProgressionFormat.equipment(["Pull-up bar"]) == "Drążek")
        #expect(ProgressionFormat.equipment(["Pull-up bar", "Rings"]) == "Drążek · Kółka")
        #expect(ProgressionFormat.equipment(ExerciseCatalog.flagEquipment) == "Pionowy drążek · Drabinki gimnastyczne")
    }

    @Test func spokenCriterionSpellsUnitsForVoiceOver() {
        #expect(MeasureFormat.spokenCriterion(.setsOfReps(sets: 3, reps: 8)) == "3 serie po 8 powtórzeń")
        #expect(MeasureFormat.spokenCriterion(.setsOfHold(sets: 3, seconds: 20)) == "3 serie po 20 sekund")
    }

    @Test func unilateralRungsCountPerSide() throws {
        let archer = try #require(ProgressionCatalog.path(withID: .pullUp)?.steps.last)
        #expect(archer.exerciseID == ExerciseCatalog.archerPullUpsID)
        #expect(MeasureFormat.criterion(for: archer) == "3 × 5 na rękę")
        #expect(MeasureFormat.spokenCriterion(for: archer) == "3 serie po 5 powtórzeń na rękę")

        let lSit = try #require(ProgressionCatalog.path(withID: .lSit)?.steps.first { $0.exerciseID == ExerciseCatalog.oneLegLSitID })
        #expect(MeasureFormat.criterion(for: lSit) == "3 × 20 s na stronę")

        let pistol = try #require(ProgressionCatalog.path(withID: .legs)?.steps.last)
        let progress = RungProgress(criterion: pistol.criterion, bestValue: 3)
        #expect(MeasureFormat.progressLine(progress, side: pistol.unilateralSide) == "3 × 5 na nogę — Twoje najlepsze: 3 × 3")

        let pullUps = try #require(ProgressionCatalog.path(withID: .pullUp)?.steps.first { $0.exerciseID == ExerciseCatalog.pullUpsID })
        #expect(MeasureFormat.criterion(for: pullUps) == "3 × 8")
    }
}

// MARK: - View model mapping

@MainActor
struct SkillPathsViewModelTests {
    private func makeViewModel(logs: [WorkoutLogEntry] = [],
                               placement: SkillPlacement? = nil) -> SkillPathsViewModel {
        TrainingStack(
            logStore: InMemoryWorkoutLogStore(initial: logs),
            placementStore: InMemorySkillPlacementStore(initial: placement)
        ).skillPaths()
    }

    @Test func freshAthleteStartsAtTheBottomOfEveryPath() {
        let viewModel = makeViewModel()

        #expect(viewModel.hasPlacement == false)
        #expect(viewModel.level.level == 1)
        #expect(viewModel.summaries.count == ProgressionCatalog.all.count)
        #expect(viewModel.summaries.allSatisfy { $0.state.currentRungIndex == 0 })
        #expect(viewModel.summaries.allSatisfy { $0.state.conqueredRungCount == 0 })
    }

    @Test func placementSetsTheCurrentRung() throws {
        // Declaring full pull-ups (rung 5) conquers everything below it.
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID])
        let viewModel = makeViewModel(placement: placement)

        #expect(viewModel.hasPlacement)
        let pullUp = try #require(viewModel.summary(for: .pullUp))
        #expect(pullUp.state.currentRungIndex == 5)
        #expect(pullUp.state.conqueredRungCount == 5)
        #expect(pullUp.currentStep.exerciseID == ExerciseCatalog.pullUpsID)
    }

    @Test func logsAdvanceThePathAndScoreTheRung() throws {
        let logs = [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
            )
        ]
        let viewModel = makeViewModel(logs: logs)

        let pullUp = try #require(viewModel.summary(for: .pullUp))
        // Conquering full pull-ups (index 5) puts the athlete on L-pull-ups (6).
        #expect(pullUp.state.currentRungIndex == 6)
        #expect(pullUp.currentStep.exerciseID == ExerciseCatalog.lPullUpsID)

        // Volume plus six conquered rungs lifts the athlete past level 1.
        #expect(viewModel.level.level == 2)
    }

    @Test func rungProgressScoresAnyRungFromLogs() throws {
        let logs = [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
            )
        ]
        let viewModel = makeViewModel(logs: logs)
        let path = try #require(ProgressionCatalog.path(withID: .pullUp))
        let pullUpStep = try #require(path.steps.first { $0.exerciseID == ExerciseCatalog.pullUpsID })

        let progress = viewModel.rungProgress(for: pullUpStep)
        #expect(progress.bestValue == 6)
        #expect(progress.isMet == false)
    }

    @Test func trainingUpdatesTheProjectionWithoutAReload() async throws {
        let stack = TrainingStack()
        let viewModel = stack.skillPaths()
        #expect(viewModel.summary(for: .pullUp)?.state.conqueredRungCount == 0)

        try await stack.journal.log(
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
            )
        )

        #expect(viewModel.summary(for: .pullUp)?.state.conqueredRungCount == 6)
    }
}
