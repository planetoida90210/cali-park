//
//  RewardLoopTests.swift
//  cali-parkTests
//
//  The reward loop: the pure evaluator that turns logs plus the
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

    /// The rung references the full-pull-up session conquers (indices 0…5;
    /// full pull-ups sit at index 5).
    static let conqueredPullUpRungs = (0...5).map { RungReference(pathID: .pullUp, rungIndex: $0)! }
}

// MARK: - RewardEvaluator

struct RewardEvaluatorTests {
    @Test func firstEvaluationSeedsABaselineAndCelebratesNothing() {
        let evaluation = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: nil)

        #expect(evaluation.pendingEvents.isEmpty)
        #expect(RewardFixture.conqueredPullUpRungs.allSatisfy { evaluation.updatedProgress.celebratedRungs.contains($0) })
        // Volume plus six conquered rungs already lifts the athlete to level 2.
        #expect(evaluation.updatedProgress.celebratedLevel == 2)
    }

    @Test func newlyConqueredRungsBecomeEvents() {
        // Baseline from an empty history: nothing conquered, level 1.
        let baseline = RewardEvaluator.evaluate(logs: [], placement: nil, celebrated: nil).updatedProgress
        #expect(baseline == .empty)

        let evaluation = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: baseline)

        let rungEvents = evaluation.pendingEvents.compactMap { event -> RungReference? in
            if case .rungConquered(let rung) = event { return rung }
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

        // Until the events are shown they stay pending: nothing is lost.
        let unshown = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: first.updatedProgress)
        #expect(unshown.pendingEvents == first.pendingEvents)

        // Once each is marked as shown, re-evaluating the same logs yields nothing.
        let shown = first.pendingEvents.reduce(first.updatedProgress) { $0.markingCelebrated($1) }
        let second = RewardEvaluator.evaluate(logs: [RewardFixture.pullUps3x8()], placement: nil, celebrated: shown)
        #expect(second.pendingEvents.isEmpty)
    }

    @Test func rungsBelowTheDeclaredFloorDoNotCelebrate() {
        // A pro who declared archer (rung 7) logs full pull-ups (rung 5) — below
        // their declaration. That is not a fresh advance, so nothing celebrates.
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.archerPullUpsID])
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
        if case .rungConquered(let rung) = firstRung {
            // Pull-up precedes dip in the catalog, so its rung 0 comes first.
            #expect(rung == RungReference(pathID: .pullUp, rungIndex: 0)!)
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

        let presentation = CelebrationPresentation.resolving(.rungConquered(RungReference(pathID: .pullUp, rungIndex: 4)!))

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

// MARK: - App-wide reward loop

@MainActor
struct RewardCenterLoopTests {
    @Test func aFreshAthleteHasNoCelebrationAndNoBadges() {
        let stack = TrainingStack()

        #expect(stack.rewards.currentCelebration == nil)
        #expect(stack.skillPaths().badges.isEmpty)
        #expect(stack.rewards.xpToastAmount == nil)
    }

    @Test func declaringAPlacementNeverCelebrates() {
        // A declaration conquers rungs, but the reward loop scores from logs
        // only — so nothing is celebrated and no badge is granted.
        let stack = TrainingStack(
            placementStore: InMemorySkillPlacementStore(
                initial: SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.archerPullUpsID]))
        )

        #expect(stack.rewards.currentCelebration == nil)
        #expect(stack.skillPaths().badges.isEmpty)
    }

    @Test func trainingANewRungQueuesACelebration() async throws {
        let stack = TrainingStack()
        #expect(stack.rewards.currentCelebration == nil)

        try await stack.journal.log(RewardFixture.pullUps3x8())
        await stack.settle()

        #expect(stack.rewards.currentCelebration == .rungs(0...5, on: .pullUp))
        // The XP toast stays silent while a celebration carries the moment.
        #expect(stack.rewards.xpToastAmount == nil)

        // Draining the queue eventually clears the overlay, once.
        stack.drainCelebrations()
        #expect(stack.rewards.currentCelebration == nil)

        // Refreshing the same logs celebrates nothing (idempotent).
        stack.rewards.refresh()
        #expect(stack.rewards.currentCelebration == nil)
    }

    @Test func addedVolumeOnAConqueredRungToastsXPWithoutCelebrating() async throws {
        // Start already at the baseline (a 3 × 8 pre-logged), so its rungs are
        // seeded as celebrated on the first evaluation.
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [RewardFixture.pullUps3x8()]))
        #expect(stack.rewards.currentCelebration == nil)
        #expect(stack.rewards.xpToastAmount == nil)

        // More volume on an already-conquered rung: XP grows, nothing new is
        // conquered, so the athlete gets a toast, not an overlay.
        try await stack.journal.log(RewardFixture.pullUps3x8())
        await stack.settle()

        #expect(stack.rewards.currentCelebration == nil)
        let toast = try #require(stack.rewards.xpToastAmount)
        #expect(toast == 24 * ProgressionEngine.xpPerRep)
    }

    @Test func earnedBadgesComeFromLogs() async throws {
        let stack = TrainingStack()

        try await stack.journal.log(RewardFixture.pullUps3x8())
        await stack.settle()

        #expect(stack.skillPaths().badges.contains(.firstWorkout))
    }
}

// MARK: - XP toast for VoiceOver

@MainActor
struct XPToastSpokenTextTests {
    @Test
    func announcementSaysTheEarnedXP() {
        #expect(XPToastView.spokenText(amount: 30) == "Zdobyto 30 XP")
    }
}
