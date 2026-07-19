//
//  RewardLoopTests.swift
//  cali-parkTests
//
//  Sprint SK6a — the reward loop: the pure evaluator that turns logs plus the
//  "already celebrated" record into celebration events (log-only, idempotent,
//  baseline-not-flood), the celebration copy, and the Skills view model's queue
//  and XP toast. Pure and deterministic: in-memory stores, no timing.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum RewardFixture {
    /// A clean 3 × 8 of full pull-ups — conquers pull-up rungs 0…4.
    static func pullUps3x8() -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
        )
    }

    /// The rung references the full-pull-up session conquers (indices 0…4).
    static let conqueredPullUpRungs = (0...4).map { RungReference(pathID: .pullUp, rungIndex: $0) }
}

// MARK: - RewardEvaluator

struct RewardEvaluatorTests {
    @Test func firstEvaluationSeedsABaselineAndCelebratesNothing() {
        let evaluation = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: nil)

        #expect(evaluation.pendingEvents.isEmpty)
        #expect(RewardFixture.conqueredPullUpRungs.allSatisfy { evaluation.updatedProgress.celebratedRungs.contains($0) })
        // Volume plus five conquered rungs already lifts the athlete to level 2.
        #expect(evaluation.updatedProgress.celebratedLevel == 2)
    }

    @Test func newlyConqueredRungsBecomeEvents() {
        // Baseline from an empty history: nothing conquered, level 1.
        let baseline = RewardEvaluator.evaluate(logs: [], placement: nil, celebrated: nil).updatedProgress
        #expect(baseline == .empty)

        let evaluation = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: baseline)

        let rungEvents = evaluation.pendingEvents.compactMap { event -> RungReference? in
            if case let .rungConquered(rung) = event { return rung }
            return nil
        }
        #expect(rungEvents == RewardFixture.conqueredPullUpRungs)
    }

    @Test func levelUpIsCelebratedAfterTheRungs() {
        let baseline = RewardEvaluator.evaluate(logs: [], placement: nil, celebrated: nil).updatedProgress
        let evaluation = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: baseline)

        // The level-up is the finale: it trails the rung advances.
        #expect(evaluation.pendingEvents.last == .levelReached(2))
    }

    @Test func evaluationIsIdempotent() {
        let baseline = RewardEvaluator.evaluate(logs: [], placement: nil, celebrated: nil).updatedProgress
        let first = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: baseline)
        #expect(first.pendingEvents.isEmpty == false)

        // Persisting `updatedProgress` and re-evaluating the same logs yields nothing.
        let second = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: first.updatedProgress)
        #expect(second.pendingEvents.isEmpty)
    }

    @Test func rungsBelowTheDeclaredFloorDoNotCelebrate() {
        // A pro who declared archer (rung 6) logs full pull-ups (rung 4) — below
        // their declaration. That is not a fresh advance, so nothing celebrates.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 6])
        let baseline = RewardEvaluator.evaluate(logs: [], placement: placement, celebrated: nil).updatedProgress
        let evaluation = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: placement, celebrated: baseline)

        let rungEvents = evaluation.pendingEvents.filter {
            if case .rungConquered = $0 { return true }
            return false
        }
        #expect(rungEvents.isEmpty)
    }

    @Test func rungEventsAreOrderedByCatalogThenIndex() {
        let baseline = RewardEvaluator.evaluate(logs: [], placement: nil, celebrated: nil).updatedProgress
        let logs = [
            RewardFixture.pullUps3x8(),
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.dipsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
            )
        ]
        let events = RewardEvaluator.evaluate(logs: logs, placement: nil, celebrated: baseline).pendingEvents

        let firstRung = events.first
        if case let .rungConquered(rung) = firstRung {
            // Pull-up precedes dip in the catalog, so its rung 0 comes first.
            #expect(rung == RungReference(pathID: .pullUp, rungIndex: 0))
        } else {
            Issue.record("Expected a rung event first, got \(String(describing: firstRung))")
        }
    }
}

// MARK: - CelebrationPresentation

struct CelebrationPresentationTests {
    @Test func rungResolvesExerciseNamePathAndXP() throws {
        let path = try #require(ProgressionCatalog.path(withID: .pullUp))
        let step = path.steps[4]
        let exercise = try #require(ExerciseCatalog.exercise(withID: step.exerciseID))

        let presentation = CelebrationPresentation.resolving(.rungConquered(RungReference(pathID: .pullUp, rungIndex: 4)))

        #expect(presentation.eyebrow == "ZALICZONY SZCZEBEL")
        #expect(presentation.title == exercise.name)
        #expect(presentation.subtitle == path.name)
        #expect(presentation.xpNote == "+\(ProgressionEngine.xpPerConqueredRung) XP")
        #expect(presentation.symbolName == path.symbolName)
    }

    @Test func levelResolvesToNumberedTitle() {
        let presentation = CelebrationPresentation.resolving(.levelReached(3))

        #expect(presentation.eyebrow == "NOWY POZIOM")
        #expect(presentation.title == "Poziom 3")
        #expect(presentation.subtitle == nil)
        #expect(presentation.xpNote == nil)
    }
}

// MARK: - View model reward loop

@MainActor
struct SkillPathsRewardTests {
    @Test func aFreshAthleteHasNoCelebrationAndNoBadges() {
        let viewModel = SkillPathsViewModel(
            logStore: InMemoryWorkoutLogStore(),
            placementStore: InMemorySkillPlacementStore(),
            progressStore: InMemorySkillProgressStore()
        )

        #expect(viewModel.currentCelebration == nil)
        #expect(viewModel.badges.isEmpty)
        #expect(viewModel.xpToastAmount == nil)
    }

    @Test func declaringAPlacementNeverCelebrates() {
        // A declaration conquers rungs, but the reward loop scores from logs
        // only — so nothing is celebrated and no badge is granted.
        let viewModel = SkillPathsViewModel(
            logStore: InMemoryWorkoutLogStore(),
            placementStore: InMemorySkillPlacementStore(initial: SkillPlacement(declaredRungByPath: [.pullUp: 6])),
            progressStore: InMemorySkillProgressStore()
        )

        #expect(viewModel.currentCelebration == nil)
        #expect(viewModel.badges.isEmpty)
    }

    @Test func trainingANewRungQueuesACelebration() throws {
        let store = InMemoryWorkoutLogStore()
        let viewModel = SkillPathsViewModel(
            logStore: store,
            placementStore: InMemorySkillPlacementStore(),
            progressStore: InMemorySkillProgressStore()
        )
        #expect(viewModel.currentCelebration == nil)

        try store.append(RewardFixture.pullUps3x8())
        viewModel.load()

        #expect(viewModel.currentCelebration != nil)
        // The XP toast stays silent while a celebration carries the moment.
        #expect(viewModel.xpToastAmount == nil)

        // Draining the queue eventually clears the overlay, once.
        var guardRail = 0
        while viewModel.currentCelebration != nil, guardRail < 100 {
            viewModel.dismissCurrentCelebration()
            guardRail += 1
        }
        #expect(viewModel.currentCelebration == nil)

        // Re-loading the same logs celebrates nothing (idempotent).
        viewModel.load()
        #expect(viewModel.currentCelebration == nil)
    }

    @Test func addedVolumeOnAConqueredRungToastsXPWithoutCelebrating() throws {
        // Start already at the baseline (a 3 × 8 pre-logged), so its rungs are
        // seeded as celebrated on the first load.
        let store = InMemoryWorkoutLogStore(initial: [RewardFixture.pullUps3x8()])
        let viewModel = SkillPathsViewModel(
            logStore: store,
            placementStore: InMemorySkillPlacementStore(),
            progressStore: InMemorySkillProgressStore()
        )
        #expect(viewModel.currentCelebration == nil)
        #expect(viewModel.xpToastAmount == nil)

        // More volume on an already-conquered rung: XP grows, nothing new is
        // conquered, so the athlete gets a toast, not an overlay.
        try store.append(RewardFixture.pullUps3x8())
        viewModel.load()

        #expect(viewModel.currentCelebration == nil)
        let toast = try #require(viewModel.xpToastAmount)
        #expect(toast == 24 * ProgressionEngine.xpPerRep)
    }

    @Test func earnedBadgesComeFromLogs() throws {
        let store = InMemoryWorkoutLogStore()
        let viewModel = SkillPathsViewModel(
            logStore: store,
            placementStore: InMemorySkillPlacementStore(),
            progressStore: InMemorySkillProgressStore()
        )

        try store.append(RewardFixture.pullUps3x8())
        viewModel.load()

        #expect(viewModel.badges.contains(.firstWorkout))
    }
}
