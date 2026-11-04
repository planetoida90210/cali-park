//
//  HomeHeroActionsTests.swift
//  cali-parkTests
//
//  Home hero integration: the contextual actions wired into
//  HomeView must move the hero through the right states as the user acts.
//  These exercise the same seams the view uses (the factories
//  `makeQuickWorkoutViewModel(plan:)` / `makeQuickWorkoutViewModel()` and
//  `reload()`), proving each state's CTA does a real thing and the hero reacts.
//

import Foundation
import Testing
@testable import cali_park

@MainActor
struct HomeHeroActionsTests {
    private func makeHome(logStore: WorkoutLogStoring,
                          planStore: WorkoutPlanStoring) -> HomeHarness {
        HomeHarness(logStore: logStore, planStore: planStore,
                    calendar: TestCalendar.utc, clock: { TestDate.reference })
    }

    /// planToday → tapping "Rozpocznij" (a plan-seeded quick workout) and
    /// finishing it stamps today's plan and flips the hero to completedToday.
    @Test
    func startingTodaysPlanThenFinishingMovesHeroToCompleted() async throws {
        let plan = WorkoutPlan(
            name: "Push Day",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 12)],
            schedule: .once(TestDate.reference, in: TestCalendar.utc)
        )
        let logStore = InMemoryWorkoutLogStore()
        let home = makeHome(logStore: logStore, planStore: InMemoryWorkoutPlanStore(initial: [plan]))
        let dashboard = home.dashboard

        #expect(dashboard.heroState().isPlanToday)

        // onStartPlan(plan) in the view resolves to this factory.
        let session = home.makeQuickWorkoutViewModel(plan: plan)
        await session.finish()
        dashboard.reload()

        #expect(logStore.load().allSatisfy { $0.planID == plan.id })
        #expect(dashboard.heroState().isCompletedToday)
    }

    /// firstRun → the rail's "Szybki trening" (same VM seam) finishing a free
    /// session flips the hero to completedToday. The firstRun hero itself only
    /// invites; the action lives in the permanent rail.
    @Test
    func quickWorkoutFromFirstRunMovesHeroToCompleted() async throws {
        let logStore = InMemoryWorkoutLogStore()
        let home = makeHome(logStore: logStore, planStore: InMemoryWorkoutPlanStore())
        let dashboard = home.dashboard

        #expect(dashboard.heroState() == .firstRun)

        // onQuickWorkout in the view resolves to this factory.
        let session = home.makeQuickWorkoutViewModel()
        session.addExercise(ExerciseCatalog.all[0], sets: [LoggedSet(reps: 10)])
        await session.finish()
        dashboard.reload()

        let saved = logStore.load()
        #expect(saved.count == 1)
        #expect(saved.first?.planID == nil)
        #expect(dashboard.heroState().isCompletedToday)
    }

    /// A session started from Home finishes at Home's clock, not the wall
    /// clock, so "done today" and the saved entries agree.
    @Test
    func aSessionFromHomeIsStampedWithHomesClock() async throws {
        let logStore = InMemoryWorkoutLogStore()
        let home = makeHome(logStore: logStore, planStore: InMemoryWorkoutPlanStore())

        let session = home.makeQuickWorkoutViewModel()
        session.addExercise(ExerciseCatalog.all[0], sets: [LoggedSet(reps: 10)])
        await session.finish()

        #expect(logStore.load().map(\.date) == [TestDate.reference])
    }

    /// A free (unplanned) log while a plan is due today is progress, not "done":
    /// the hero stays on planToday so the plan's CTA remains available.
    @Test
    func freeLogWhilePlanDueKeepsHeroOnPlanToday() async throws {
        let plan = WorkoutPlan(
            name: "Push Day",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
            schedule: .once(TestDate.reference, in: TestCalendar.utc)
        )
        let logStore = InMemoryWorkoutLogStore()
        let home = makeHome(logStore: logStore, planStore: InMemoryWorkoutPlanStore(initial: [plan]))
        let dashboard = home.dashboard

        let free = home.makeQuickWorkoutViewModel()
        free.addExercise(ExerciseCatalog.all[0], sets: [LoggedSet(reps: 8)])
        await free.finish()
        dashboard.reload()

        guard case let .planToday(resolvedPlan, loggedTodayReps, _) = dashboard.heroState() else {
            Issue.record("expected .planToday after a free log")
            return
        }
        #expect(resolvedPlan == plan)
        #expect(loggedTodayReps == 8)
    }
}
