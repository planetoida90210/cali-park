//
//  HomeFreshnessTests.swift
//  cali-parkTests
//
//  Audit B-3 / D-17: Home's "today" must follow the clock. Every derived
//  value reads the dashboard's cached `now`, which `reload()` refreshes; the
//  view calls `reload()` when the scene becomes active and when the calendar
//  day changes. These tests move an injected clock across midnight.
//  Audit B-4: a workout deleted from the post-finish summary disappears from
//  Home once the sheet's dismissal reloads the dashboard.
//

import Foundation
import Testing
@testable import cali_park

/// A clock the test moves by hand.
private final class TestClock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

private enum Fixtures {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-11-02T21:00:00Z, a Monday evening.
    static let mondayEvening = Date(timeIntervalSince1970: 1_793_653_200)
    /// 2026-11-03T08:00:00Z, the next (Tuesday) morning.
    static let tuesdayMorning = Date(timeIntervalSince1970: 1_793_692_800)

    static func entry(on date: Date, planID: UUID? = nil) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, date: date,
                        sets: [LoggedSet(reps: 8)], sessionID: UUID(), planID: planID)
    }
}

private extension HomeHeroState {
    var isPlanToday: Bool { if case .planToday = self { return true } else { return false } }
    var isCompletedToday: Bool { if case .completedToday = self { return true } else { return false } }
    var isRestDay: Bool { if case .restDay = self { return true } else { return false } }
}

// MARK: - Day rollover (B-3 / D-17)

@MainActor
struct HomeDayRolloverTests {
    private func dashboard(clock: TestClock,
                           plans: [WorkoutPlan] = [],
                           entries: [WorkoutLogEntry] = []) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: entries),
            planService: .testing(InMemoryWorkoutPlanStore(initial: plans)),
            calendar: Fixtures.calendar,
            clock: { clock.now }
        )
    }

    @Test
    func nowIsReadFromTheInjectedClock() {
        let clock = TestClock(Fixtures.mondayEvening)
        #expect(dashboard(clock: clock).now == Fixtures.mondayEvening)
    }

    /// Without a reload the cached day holds, so a render keeps one consistent
    /// "today"; a reload moves it.
    @Test
    func reloadMovesNowToTheCurrentTime() {
        let clock = TestClock(Fixtures.mondayEvening)
        let dashboard = dashboard(clock: clock)

        clock.now = Fixtures.tuesdayMorning
        #expect(dashboard.now == Fixtures.mondayEvening)

        dashboard.reload()
        #expect(dashboard.now == Fixtures.tuesdayMorning)
    }

    /// Trained Monday night, Tuesday's plan is due: the next morning Home must
    /// offer Tuesday's plan instead of "done today".
    @Test
    func heroMovesFromDoneTodayToTodaysPlanAfterMidnight() {
        let tuesdayPlan = WorkoutPlan(
            name: "Push",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
            schedule: .weekly([.tuesday])
        )
        let clock = TestClock(Fixtures.mondayEvening)
        let dashboard = dashboard(clock: clock, plans: [tuesdayPlan],
                                  entries: [Fixtures.entry(on: Fixtures.mondayEvening - 3_600)])
        #expect(dashboard.heroState().isCompletedToday)

        clock.now = Fixtures.tuesdayMorning
        dashboard.reload()

        guard case let .planToday(plan, loggedTodayReps) = dashboard.heroState() else {
            Issue.record("Expected planToday, got \(dashboard.heroState())")
            return
        }
        #expect(plan.id == tuesdayPlan.id)
        #expect(loggedTodayReps == 0)
    }

    @Test
    func nextPlannedWorkoutFollowsTheRefreshedDay() throws {
        let tuesdayPlan = WorkoutPlan(
            name: "Push",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
            schedule: .weekly([.tuesday])
        )
        let clock = TestClock(Fixtures.mondayEvening)
        let dashboard = dashboard(clock: clock, plans: [tuesdayPlan])

        let before = try #require(dashboard.nextPlannedWorkout)
        #expect(WorkoutScheduleFormatter.dayLabel(before.date, asOf: dashboard.now, calendar: Fixtures.calendar) == "Jutro")
        #expect(dashboard.heroState().isRestDay)

        clock.now = Fixtures.tuesdayMorning
        dashboard.reload()

        let after = try #require(dashboard.nextPlannedWorkout)
        #expect(after.date == before.date)
        #expect(WorkoutScheduleFormatter.dayLabel(after.date, asOf: dashboard.now, calendar: Fixtures.calendar) == "Dziś")
        #expect(dashboard.heroState().isPlanToday)
    }

    /// The streak's "today" moves too: a Monday workout still counts on
    /// Tuesday morning (the streak stays alive until a whole day is missed).
    @Test
    func streakUsesTheRefreshedDay() {
        let clock = TestClock(Fixtures.mondayEvening)
        let dashboard = dashboard(clock: clock,
                                  entries: [Fixtures.entry(on: Fixtures.mondayEvening - 3_600)])
        #expect(dashboard.streak == dashboard.streak(asOf: Fixtures.mondayEvening))

        clock.now = Fixtures.tuesdayMorning
        dashboard.reload()
        #expect(dashboard.streak == dashboard.streak(asOf: Fixtures.tuesdayMorning))
    }

    /// The weekly pull-up count resets when the week rolls over (Monday-first
    /// weeks start on the injected calendar's first weekday).
    @Test
    func weeklyPullUpsUseTheInjectedCalendarAndClock() {
        var calendar = Fixtures.calendar
        calendar.firstWeekday = 2 // Monday
        let clock = TestClock(Fixtures.mondayEvening - 2 * 86_400) // Saturday
        let dashboard = HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: [Fixtures.entry(on: clock.now - 3_600)]),
            planService: .testing(InMemoryWorkoutPlanStore()),
            calendar: calendar,
            clock: { clock.now }
        )
        #expect(dashboard.weeklyPullUps == 8)

        clock.now = Fixtures.mondayEvening
        dashboard.reload()
        #expect(dashboard.weeklyPullUps == 0)
    }
}

// MARK: - Delete from the summary (B-4)

@MainActor
struct HomeReloadAfterSummaryDeleteTests {
    /// Rail → Szybki trening → Zakończ → summary → Usuń trening. The rail's
    /// sheet reloads the dashboard on dismiss, which drops the deleted workout.
    @Test
    func deletedWorkoutLeavesHomeAfterReload() throws {
        let logStore = InMemoryWorkoutLogStore()
        let dashboard = HomeDashboardViewModel(store: logStore, planService: .testing(InMemoryWorkoutPlanStore()))

        let session = dashboard.makeQuickWorkoutViewModel()
        session.addExercise(try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)),
                            sets: [LoggedSet(reps: 8)])
        session.finish()
        dashboard.reload() // onFinish
        #expect(dashboard.heroState().isCompletedToday)

        let summary = session.makeSummaryViewModel()
        summary.delete()
        #expect(summary.didDelete)

        dashboard.reload() // the sheet's onDismiss
        #expect(dashboard.latestWorkout == nil)
        #expect(dashboard.heroState() == .firstRun)
    }
}
