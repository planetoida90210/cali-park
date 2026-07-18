//
//  HomeHeroActionsTests.swift
//  cali-parkTests
//
//  Sprint H3 — Home hero integration: the contextual actions wired into
//  HomeView must move the hero through the right states as the user acts.
//  These exercise the same view-model seams the view uses (the factories
//  `makeQuickWorkoutViewModel(plan:)` / `makeQuickWorkoutViewModel()` and
//  `reload()`), proving each state's CTA does a real thing and the hero reacts.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Case probes (test-only)

private extension HomeHeroState {
    var isPlanToday: Bool { if case .planToday = self { return true } else { return false } }
    var isCompletedToday: Bool { if case .completedToday = self { return true } else { return false } }
}

@MainActor
struct HomeHeroActionsTests {
    private func dashboard(logStore: WorkoutLogStoring,
                           planStore: WorkoutPlanStoring) -> HomeDashboardViewModel {
        HomeDashboardViewModel(store: logStore, planStore: planStore)
    }

    /// planToday → tapping "Rozpocznij" (a plan-seeded quick workout) and
    /// finishing it stamps today's plan and flips the hero to completedToday.
    @Test
    func startingTodaysPlanThenFinishingMovesHeroToCompleted() throws {
        let plan = WorkoutPlan(
            name: "Push Day",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 12)],
            schedule: .once(.now)
        )
        let logStore = InMemoryWorkoutLogStore()
        let dashboard = dashboard(logStore: logStore, planStore: InMemoryWorkoutPlanStore(initial: [plan]))

        #expect(dashboard.heroState().isPlanToday)

        // onStartPlan(plan) in the view resolves to this factory.
        let session = dashboard.makeQuickWorkoutViewModel(plan: plan)
        session.finish()
        dashboard.reload()

        #expect(logStore.load().allSatisfy { $0.planID == plan.id })
        #expect(dashboard.heroState().isCompletedToday)
    }

    /// firstRun → the rail's "Szybki trening" (same VM seam) finishing a free
    /// session flips the hero to completedToday. The firstRun hero itself only
    /// invites; the action lives in the permanent rail.
    @Test
    func quickWorkoutFromFirstRunMovesHeroToCompleted() throws {
        let logStore = InMemoryWorkoutLogStore()
        let dashboard = dashboard(logStore: logStore, planStore: InMemoryWorkoutPlanStore())

        #expect(dashboard.heroState() == .firstRun)

        // onQuickWorkout in the view resolves to this factory.
        let session = dashboard.makeQuickWorkoutViewModel()
        session.addExercise(ExerciseCatalog.all[0], sets: [LoggedSet(reps: 10)])
        session.finish()
        dashboard.reload()

        let saved = logStore.load()
        #expect(saved.count == 1)
        #expect(saved.first?.planID == nil)
        #expect(dashboard.heroState().isCompletedToday)
    }

    /// A free (unplanned) log while a plan is due today is progress, not "done":
    /// the hero stays on planToday so the plan's CTA remains available.
    @Test
    func freeLogWhilePlanDueKeepsHeroOnPlanToday() throws {
        let plan = WorkoutPlan(
            name: "Push Day",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
            schedule: .once(.now)
        )
        let logStore = InMemoryWorkoutLogStore()
        let dashboard = dashboard(logStore: logStore, planStore: InMemoryWorkoutPlanStore(initial: [plan]))

        let free = dashboard.makeQuickWorkoutViewModel()
        free.addExercise(ExerciseCatalog.all[0], sets: [LoggedSet(reps: 8)])
        free.finish()
        dashboard.reload()

        guard case let .planToday(resolvedPlan, loggedTodayReps) = dashboard.heroState() else {
            Issue.record("expected .planToday after a free log")
            return
        }
        #expect(resolvedPlan == plan)
        #expect(loggedTodayReps == 8)
    }
}
