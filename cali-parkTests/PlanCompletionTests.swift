//
//  PlanCompletionTests.swift
//  cali-parkTests
//
//  B-5: a plan is done for a day when any entry that day carries its plan id.
//  Home offers the next undone plan due today, and shows today's plans as done
//  once all of them are.
//

import Foundation
import Testing

@testable import cali_park

private enum Fixtures {
    /// UTC calendar so day boundaries never depend on the machine's timezone.
    static let calendar = TestCalendar.utc

    /// Epoch day `n`. Day 0 (1970-01-01) is a Thursday.
    static func day(_ n: Int) -> Date {
        TestDate.epochDay(n)
    }

    static let today = day(0) + 12 * 3_600 // Thursday noon

    /// Two plans due every Thursday; "Mobilność" is the older one.
    static let mobility = WorkoutPlan(
        name: "Mobilność",
        exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)],
        schedule: .weekly([.thursday]),
        createdAt: day(-30))
    static let push = WorkoutPlan(
        name: "Push",
        exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
        schedule: .weekly([.monday, .thursday]),
        createdAt: day(-20))

    static func entry(at date: Date, plan: WorkoutPlan? = nil) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: date,
            sets: [LoggedSet(reps: 8)],
            planID: plan?.id)
    }
}

// MARK: - PlanAgenda

struct PlanAgendaTests {
    private let plans = [Fixtures.push, Fixtures.mobility]

    @Test
    func twoPlansDueOneDoneOffersTheOther() {
        let entries = [Fixtures.entry(at: Fixtures.day(0) + 8 * 3_600, plan: Fixtures.mobility)]

        let today = PlanAgenda.day(Fixtures.today, plans: plans, entries: entries, calendar: Fixtures.calendar)
        let next = PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: Fixtures.calendar, today: Fixtures.today)

        #expect(today.due == [Fixtures.mobility, Fixtures.push]) // older plan first
        #expect(today.undone == [Fixtures.push])
        #expect(today.isAllDone == false)
        #expect(next == PlanAgenda.Occurrence(plan: Fixtures.push, date: Fixtures.day(0)))
    }

    @Test
    func allDoneMovesEachPlanToItsNextDay() {
        let entries = [
            Fixtures.entry(at: Fixtures.day(0) + 8 * 3_600, plan: Fixtures.mobility),
            Fixtures.entry(at: Fixtures.day(0) + 9 * 3_600, plan: Fixtures.push)
        ]

        let today = PlanAgenda.day(Fixtures.today, plans: plans, entries: entries, calendar: Fixtures.calendar)
        let next = PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: Fixtures.calendar, today: Fixtures.today)

        #expect(today.isAllDone)
        // Push also runs on Mondays (day 4); Mobilność only next Thursday.
        #expect(next == PlanAgenda.Occurrence(plan: Fixtures.push, date: Fixtures.day(4)))
    }

    @Test
    func entryWithoutPlanIDDoesNotCompleteAPlan() {
        let entries = [Fixtures.entry(at: Fixtures.day(0) + 8 * 3_600)]

        let today = PlanAgenda.day(Fixtures.today, plans: plans, entries: entries, calendar: Fixtures.calendar)

        #expect(today.undone == [Fixtures.mobility, Fixtures.push])
        #expect(PlanAgenda.isDone(Fixtures.mobility, on: Fixtures.today, entries: entries, calendar: Fixtures.calendar) == false)
    }

    @Test
    func entryJustBeforeMidnightBelongsToThePreviousDay() {
        let lastNight = Fixtures.entry(at: Fixtures.day(0) - 1, plan: Fixtures.mobility)

        #expect(PlanAgenda.isDone(Fixtures.mobility, on: Fixtures.today, entries: [lastNight], calendar: Fixtures.calendar) == false)
        #expect(PlanAgenda.isDone(Fixtures.mobility, on: Fixtures.day(-1), entries: [lastNight], calendar: Fixtures.calendar))
    }

    @Test
    func entryJustAfterMidnightCompletesToday() {
        let earlyMorning = Fixtures.entry(at: Fixtures.day(0) + 1, plan: Fixtures.mobility)

        #expect(PlanAgenda.isDone(Fixtures.mobility, on: Fixtures.today, entries: [earlyMorning], calendar: Fixtures.calendar))
        // Late the same day, still done.
        #expect(PlanAgenda.isDone(Fixtures.mobility, on: Fixtures.day(1) - 1, entries: [earlyMorning], calendar: Fixtures.calendar))
    }

    @Test
    func doneOneOffPlanHasNoNextOccurrence() {
        let once = WorkoutPlan(name: "Test", schedule: .once(Fixtures.day(0), in: Fixtures.calendar))
        let entries = [Fixtures.entry(at: Fixtures.today, plan: once)]

        #expect(PlanAgenda.nextUndoneDate(of: once, entries: entries, calendar: Fixtures.calendar, today: Fixtures.today) == nil)
    }

    @Test
    func inactivePlanIsNeverDue() {
        var paused = Fixtures.mobility
        paused.isActive = false

        let today = PlanAgenda.day(Fixtures.today, plans: [paused], entries: [], calendar: Fixtures.calendar)

        #expect(today.due.isEmpty)
        #expect(today.isAllDone == false)
    }
}

// MARK: - Home uses it

@MainActor
struct HomePlanCompletionTests {
    private func dashboard(entries: [WorkoutLogEntry]) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: entries),
            planService: .testing(InMemoryWorkoutPlanStore(initial: [Fixtures.push, Fixtures.mobility])),
            placementStore: InMemorySkillPlacementStore(),
            goalStore: InMemoryWeeklyGoalStore(),
            calendar: Fixtures.calendar,
            clock: { Fixtures.today }
        )
    }

    @Test
    func secondPlanTodayIsOfferedOnceTheFirstIsDone() {
        let vm = dashboard(entries: [Fixtures.entry(at: Fixtures.day(0) + 8 * 3_600, plan: Fixtures.mobility)])

        #expect(vm.heroState(asOf: Fixtures.today) == .planToday(plan: Fixtures.push, loggedTodayReps: 8))
        #expect(
            vm.nextWorkoutState(asOf: Fixtures.today)
                == .planned(PlanAgenda.Occurrence(plan: Fixtures.push, date: Fixtures.day(0))))
    }

    @Test
    func allPlansDoneShowsTheDayAsDoneNotStartable() {
        let vm = dashboard(entries: [
            Fixtures.entry(at: Fixtures.day(0) + 8 * 3_600, plan: Fixtures.mobility),
            Fixtures.entry(at: Fixtures.day(0) + 9 * 3_600, plan: Fixtures.push)
        ])

        guard case .completedToday = vm.heroState(asOf: Fixtures.today) else {
            Issue.record("expected .completedToday")
            return
        }
        #expect(
            vm.nextWorkoutState(asOf: Fixtures.today)
                == .doneToday(
                    plans: [Fixtures.mobility, Fixtures.push],
                    next: PlanAgenda.Occurrence(plan: Fixtures.push, date: Fixtures.day(4))
                ))
    }

    @Test
    func freeWorkoutLeavesTodaysPlansStartable() {
        let vm = dashboard(entries: [Fixtures.entry(at: Fixtures.day(0) + 8 * 3_600)])

        #expect(vm.heroState(asOf: Fixtures.today) == .planToday(plan: Fixtures.mobility, loggedTodayReps: 8))
        #expect(
            vm.nextWorkoutState(asOf: Fixtures.today)
                == .planned(PlanAgenda.Occurrence(plan: Fixtures.mobility, date: Fixtures.day(0))))
    }

    @Test
    func yesterdaysLateWorkoutDoesNotCompleteToday() {
        let vm = dashboard(entries: [
            Fixtures.entry(at: Fixtures.day(0) - 60, plan: Fixtures.mobility),
            Fixtures.entry(at: Fixtures.day(0) - 30, plan: Fixtures.push)
        ])

        #expect(vm.heroState(asOf: Fixtures.today) == .planToday(plan: Fixtures.mobility, loggedTodayReps: 0))
    }

    @Test
    func noPlansFallsBackToTheSuggestion() throws {
        let vm = HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: [Fixtures.entry(at: Fixtures.day(-2))]),
            planService: .testing(InMemoryWorkoutPlanStore()),
            placementStore: InMemorySkillPlacementStore(),
            goalStore: InMemoryWeeklyGoalStore(),
            calendar: Fixtures.calendar,
            clock: { Fixtures.today }
        )

        let suggestion = try #require(HomeEngine.suggestedExercise(entries: [Fixtures.entry(at: Fixtures.day(-2))]))
        #expect(vm.nextWorkoutState(asOf: Fixtures.today) == .suggestion(suggestion))
    }
}
