//
//  WeeklyGoalEvaluatorTests.swift
//  cali-parkTests
//
//  Ticket 027: Monday–Sunday weeks, goal kinds, versions, warm-up week, pauses
//  and the week streak.
//

import Foundation
import Testing
@testable import cali_park

private typealias F = WeeklyGoalFixtures

// MARK: - Week boundaries

struct WeeklyGoalWeekBoundaryTests {
    /// Every day from Monday to Sunday belongs to the week starting Monday,
    /// although the calendar's own first weekday is Sunday.
    @Test(arguments: 0..<7)
    func everyDayBelongsToTheMondayWeek(offset: Int) {
        let week = WeeklyGoalEvaluator.week(containing: F.day(offset), calendar: F.calendar)
        #expect(week.start == F.monday)
        #expect(week.end == F.date(2026, 11, 9, 0))
    }

    @Test
    func boundariesAreHalfOpen() {
        let lastSecond = F.date(2026, 11, 8, 23, 59, 59)
        let nextMonday = F.date(2026, 11, 9, 0)
        #expect(WeeklyGoalEvaluator.week(containing: lastSecond, calendar: F.calendar).start == F.monday)
        #expect(WeeklyGoalEvaluator.week(containing: nextMonday, calendar: F.calendar).start == nextMonday)
        #expect(WeeklyGoalEvaluator.week(containing: F.monday, calendar: F.calendar).start == F.monday)

        let goal = F.days(3)
        let entries = [F.entry(at: lastSecond), F.entry(at: nextMonday)]
        let progress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: entries, plans: [],
                                                    calendar: F.calendar)
        #expect(progress.value == 1)
    }

    /// ISO week 53 of 2026 runs from Monday 28 December to Sunday 3 January.
    @Test
    func weekFiftyThreeSpansTheYearBoundary() {
        let week = WeeklyGoalEvaluator.week(containing: F.date(2027, 1, 3), calendar: F.calendar)
        #expect(week.start == F.date(2026, 12, 28, 0))
        #expect(week.end == F.date(2027, 1, 4, 0))

        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = F.calendar.timeZone
        #expect(iso.component(.weekOfYear, from: week.start) == 53)

        let entries = [F.entry(at: F.date(2026, 12, 29)), F.entry(at: F.date(2027, 1, 2))]
        let progress = WeeklyGoalEvaluator.progress(of: F.days(2), in: week, entries: entries, plans: [],
                                                    calendar: F.calendar)
        #expect(progress.value == 2)
        #expect(progress.isMet)
    }

    @Test
    func weekBeforeCrossesTheYearBoundary() {
        let firstWeekOf2027 = WeeklyGoalEvaluator.week(containing: F.date(2027, 1, 5), calendar: F.calendar)
        let previous = WeeklyGoalEvaluator.week(before: firstWeekOf2027, calendar: F.calendar)
        #expect(firstWeekOf2027.start == F.date(2027, 1, 4, 0))
        #expect(previous.start == F.date(2026, 12, 28, 0))
    }

    /// A streak keeps counting across the new year.
    @Test
    func streakRunsAcrossTheNewYear() {
        let versions = [F.version([F.days(2)], from: F.date(2026, 12, 21, 0))]
        let entries = [
            F.date(2026, 12, 22), F.date(2026, 12, 23), // week of 21 Dec
            F.date(2026, 12, 31), F.date(2027, 1, 1),   // week 53
            F.date(2027, 1, 5), F.date(2027, 1, 6)      // first week of 2027
        ].map { F.entry(at: $0) }
        let streak = WeeklyGoalEvaluator.streak(versions: versions, pauses: [], entries: entries, plans: [],
                                                calendar: F.calendar, asOf: F.date(2027, 1, 7))
        #expect(streak == 3)
    }
}

// MARK: - Progress per goal kind

struct WeeklyGoalProgressTests {
    @Test
    func trainingDaysCountDistinctDays() {
        let entries = [
            F.entry(at: F.day(0, hour: 7)), F.entry(at: F.day(0, hour: 19)),
            F.entry(at: F.day(3)),
            F.entry(at: F.day(week: -1, 6)) // previous Sunday
        ]
        let progress = WeeklyGoalEvaluator.progress(of: F.days(3), in: F.week(0), entries: entries, plans: [],
                                                    calendar: F.calendar)
        #expect(progress.target == 3)
        #expect(progress.value == 2)
        #expect(progress.isMet == false)
        #expect(abs(progress.fraction - 2.0 / 3.0) < 0.0001)
    }

    @Test
    func repVolumeSumsOnlyTheChosenExercise() {
        let goal = F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 20))
        let entries = [
            F.entry(at: F.day(1), sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)]),
            F.entry(at: F.day(4), sets: [LoggedSet(reps: 7)]),
            F.entry(at: F.day(4), exercise: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 30)])
        ]
        let progress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: entries, plans: [],
                                                    calendar: F.calendar)
        #expect(progress.value == 21)
        #expect(progress.isMet)
        #expect(progress.fraction == 1)
    }

    @Test
    func secondsVolumeSumsHolds() {
        let goal = F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.lSitID, measurement: .seconds, amount: 180))
        let hold = { (seconds: Int) in LoggedSet(reps: 1, durationSeconds: seconds) }
        let entries = [
            F.entry(at: F.day(0), exercise: ExerciseCatalog.lSitID, sets: [hold(20), hold(15)]),
            F.entry(at: F.day(2), exercise: ExerciseCatalog.lSitID, sets: [hold(25)])
        ]
        let progress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: entries, plans: [],
                                                    calendar: F.calendar)
        #expect(progress.value == 60)
        #expect(progress.isMet == false)
    }

    /// One plan workout per plan per day, however many exercises it logged.
    @Test
    func plannedCountCountsPlanDays() {
        let push = WorkoutPlan(name: "Push", createdAt: F.day(week: -4))
        let pull = WorkoutPlan(name: "Pull", createdAt: F.day(week: -4))
        let goal = F.goal(.plannedWorkouts(target: .count(workouts: 3)))
        let entries = [
            F.entry(at: F.day(0, hour: 8), plan: push),
            F.entry(at: F.day(0, hour: 8), exercise: ExerciseCatalog.dipsID, plan: push),
            F.entry(at: F.day(0, hour: 18), plan: pull),
            F.entry(at: F.day(2)), // free workout
            F.entry(at: F.day(3), plan: push)
        ]
        let progress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: entries, plans: [],
                                                    calendar: F.calendar)
        #expect(progress.value == 3)
        #expect(progress.isMet)
    }

    /// "All scheduled": a session moved to another day of the same week still
    /// counts, but never more often than the plan was scheduled.
    @Test
    func allScheduledCountsMovedSessionsUpToTheSchedule() {
        let plan = WorkoutPlan(name: "FBW", schedule: .weekly([.monday, .thursday]), createdAt: F.day(week: -4))
        let goal = F.goal(.plannedWorkouts(target: .allScheduled))

        let moved = [F.entry(at: F.day(0), plan: plan), F.entry(at: F.day(4), plan: plan)] // Mon + Fri
        let movedProgress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: moved, plans: [plan],
                                                         calendar: F.calendar)
        #expect(movedProgress.target == 2)
        #expect(movedProgress.value == 2)
        #expect(movedProgress.isMet)

        let extra = moved + [F.entry(at: F.day(1), plan: plan)]
        let extraProgress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: extra, plans: [plan],
                                                         calendar: F.calendar)
        #expect(extraProgress.value == 2)
    }

    /// The schedule comes from the planner: inactive plans and days before a
    /// plan existed are not part of the target.
    @Test
    func allScheduledUsesThePlannerSchedule() {
        let old = WorkoutPlan(name: "A", schedule: .weekly([.monday, .thursday]), createdAt: F.day(week: -4))
        let inactive = WorkoutPlan(name: "B", schedule: .weekly([.tuesday]), isActive: false, createdAt: F.day(week: -4))
        let fresh = WorkoutPlan(name: "C", schedule: .everyNDays(2, from: F.day(2), in: F.calendar), createdAt: F.day(2, hour: 9))
        let once = WorkoutPlan(name: "D", schedule: .once(F.day(6), in: F.calendar), createdAt: F.day(week: -1))
        let goal = F.goal(.plannedWorkouts(target: .allScheduled))

        let progress = WeeklyGoalEvaluator.progress(of: goal, in: F.week(0), entries: [],
                                                    plans: [old, inactive, fresh, once], calendar: F.calendar)
        // A: Mon + Thu; C: Wed, Fri, Sun; D: Sun.
        #expect(progress.target == 6)
        #expect(progress.value == 0)
    }

    @Test
    func occurrencesListPlanDaysInOrder() {
        let older = WorkoutPlan(name: "Older", schedule: .weekly([.monday]), createdAt: F.day(week: -3))
        let newer = WorkoutPlan(name: "Newer", schedule: .weekly([.monday, .sunday]), createdAt: F.day(week: -2))
        let occurrences = PlanAgenda.occurrences(of: [newer, older], in: F.week(0), calendar: F.calendar)
        #expect(occurrences == [
            PlanAgenda.Occurrence(plan: older, date: F.monday),
            PlanAgenda.Occurrence(plan: newer, date: F.monday),
            PlanAgenda.Occurrence(plan: newer, date: F.day(6, hour: 0))
        ])
    }
}

// MARK: - Week verdicts and the streak

struct WeeklyGoalStreakTests {
    private func streak(_ versions: [WeeklyGoalVersion],
                        pauses: [WeeklyGoalPause] = [],
                        entries: [WorkoutLogEntry],
                        plans: [WorkoutPlan] = [],
                        asOf: Date) -> Int {
        WeeklyGoalEvaluator.streak(versions: versions, pauses: pauses, entries: entries, plans: plans,
                                   calendar: F.calendar, asOf: asOf)
    }

    private func verdict(_ week: Int,
                         _ versions: [WeeklyGoalVersion],
                         pauses: [WeeklyGoalPause] = [],
                         entries: [WorkoutLogEntry],
                         plans: [WorkoutPlan] = [],
                         asOf: Date) -> WeeklyGoalWeek? {
        WeeklyGoalEvaluator.evaluate(week: F.week(week), versions: versions, pauses: pauses, entries: entries,
                                     plans: plans, calendar: F.calendar, asOf: asOf)
    }

    private let threeDays = [F.version([F.days(3)], from: F.day(week: -10, hour: 0))]

    @Test
    func runningWeekDoesNotBreakTheStreak() {
        let entries = F.trained(week: -2, days: [0, 2, 4]) + F.trained(week: -1, days: [1, 3, 5])
            + F.trained(week: 0, days: [0])
        let now = F.day(2)
        #expect(verdict(0, threeDays, entries: entries, asOf: now)?.status == .inProgress)
        #expect(streak(threeDays, entries: entries, asOf: now) == 2)
    }

    @Test
    func metCurrentWeekCountsAtOnce() {
        let entries = F.trained(week: -1, days: [0, 1, 2]) + F.trained(week: 0, days: [0, 1, 2])
        #expect(streak(threeDays, entries: entries, asOf: F.day(3)) == 2)
    }

    @Test
    func missedWeekBreaksTheStreak() {
        let entries = F.trained(week: -3, days: [0, 1, 2]) + F.trained(week: -2, days: [0])
            + F.trained(week: -1, days: [0, 1, 2])
        #expect(verdict(-2, threeDays, entries: entries, asOf: F.day(1))?.status == .missed)
        #expect(streak(threeDays, entries: entries, asOf: F.day(1)) == 1)
    }

    /// A goal raised mid-week applies to the whole current week at once.
    @Test
    func goalChangeAppliesToTheCurrentWeekAtOnce() throws {
        let versions = threeDays + [F.version([F.days(5)], from: F.day(2))]
        let entries = F.trained(week: 0, days: [0, 1, 2])
        let current = try #require(verdict(0, versions, entries: entries, asOf: F.day(3)))
        #expect(current.primary.target == 5)
        #expect(current.status == .inProgress)
    }

    /// A closed week is judged by the version in force when it ended; weeks
    /// before keep the old goal.
    @Test
    func closedWeeksKeepTheirVersion() throws {
        let versions = threeDays + [F.version([F.days(5)], from: F.day(week: -1, 2))]
        let entries = F.trained(week: -2, days: [0, 1, 2]) + F.trained(week: -1, days: [0, 1, 2])
        let now = F.day(1)

        let changedWeek = try #require(verdict(-1, versions, entries: entries, asOf: now))
        #expect(changedWeek.primary.target == 5)
        #expect(changedWeek.status == .missed)

        let olderWeek = try #require(verdict(-2, versions, entries: entries, asOf: now))
        #expect(olderWeek.primary.target == 3)
        #expect(olderWeek.status == .met)

        #expect(streak(versions, entries: entries, asOf: now) == 0)
    }

    /// A goal changed in the current week does not touch last week.
    @Test
    func changingTheGoalNowKeepsLastWeek() {
        let versions = threeDays + [F.version([F.days(6)], from: F.day(1))]
        let entries = F.trained(week: -1, days: [0, 2, 4])
        #expect(verdict(-1, versions, entries: entries, asOf: F.day(1))?.status == .met)
        #expect(streak(versions, entries: entries, asOf: F.day(1)) == 1)
    }

    @Test
    func primaryGoalDrivesTheVerdict() throws {
        let volume = F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 100))
        let versions = [F.version([volume, F.days(1)], from: F.day(week: -5, hour: 0))]
        let week = try #require(verdict(-1, versions, entries: F.trained(week: -1, days: [0]), asOf: F.day(1)))
        #expect(week.goals[1].isMet)
        #expect(week.status == .missed)
    }

    // MARK: Warm-up

    @Test
    func warmUpWeekNotMetIsNeutral() throws {
        let versions = [F.version([F.days(3)], from: F.day(week: -2, 3, hour: 10))] // Thursday
        let entries = F.trained(week: -2, days: [4]) + F.trained(week: -1, days: [0, 2, 4])
        let warmUp = try #require(verdict(-2, versions, entries: entries, asOf: F.day(1)))
        #expect(warmUp.isWarmUp)
        #expect(warmUp.status == .warmUp)
        #expect(streak(versions, entries: entries, asOf: F.day(1)) == 1)
    }

    @Test
    func warmUpWeekMetCounts() {
        let versions = [F.version([F.days(3)], from: F.day(week: -2, 3, hour: 10))]
        let entries = F.trained(week: -2, days: [3, 4, 5]) + F.trained(week: -1, days: [0, 2, 4])
        #expect(verdict(-2, versions, entries: entries, asOf: F.day(1))?.status == .met)
        #expect(streak(versions, entries: entries, asOf: F.day(1)) == 2)
    }

    /// Set on a Monday, the first week is a full week: falling short breaks.
    @Test
    func goalSetOnMondayHasNoWarmUp() throws {
        let versions = [F.version([F.days(3)], from: F.day(week: -2, hour: 18))]
        let entries = F.trained(week: -2, days: [1]) + F.trained(week: -1, days: [0, 2, 4])
        let first = try #require(verdict(-2, versions, entries: entries, asOf: F.day(1)))
        #expect(first.isWarmUp == false)
        #expect(first.status == .missed)
        #expect(streak(versions, entries: entries, asOf: F.day(1)) == 1)
    }

    @Test
    func weeksBeforeTheFirstVersionAreNotJudged() {
        let versions = [F.version([F.days(1)], from: F.day(week: -1, hour: 0))]
        let entries = F.trained(week: -3, days: [0]) + F.trained(week: -1, days: [0])
        #expect(verdict(-2, versions, entries: entries, asOf: F.day(1)) == nil)
        #expect(streak(versions, entries: entries, asOf: F.day(1)) == 1)
    }

    // MARK: Pauses

    /// A one-week pause from Wednesday touches two weeks; both are neutral.
    @Test
    func pauseAcrossTwoWeeksKeepsTheStreak() throws {
        let pause = WeeklyGoalPause(start: F.day(week: -3, 2, hour: 0), plannedEnd: F.day(week: -2, 2, hour: 0))
        let entries = F.trained(week: -4, days: [0, 1, 2]) + F.trained(week: -1, days: [0, 1, 2])
        let now = F.day(1)

        #expect(verdict(-3, threeDays, pauses: [pause], entries: entries, asOf: now)?.status == .paused)
        #expect(verdict(-2, threeDays, pauses: [pause], entries: entries, asOf: now)?.status == .paused)
        #expect(streak(threeDays, pauses: [pause], entries: entries, asOf: now) == 2)
        #expect(streak(threeDays, entries: entries, asOf: now) == 1)
    }

    @Test
    func goalMetDuringAPauseStillCounts() {
        let pause = WeeklyGoalPause(start: F.day(week: -1, hour: 0), plannedEnd: F.day(week: -1, 3, hour: 0))
        let entries = F.trained(week: -1, days: [3, 4, 5])
        #expect(verdict(-1, threeDays, pauses: [pause], entries: entries, asOf: F.day(1))?.status == .met)
        #expect(streak(threeDays, pauses: [pause], entries: entries, asOf: F.day(1)) == 1)
    }

    /// Ended early, a pause stops covering the weeks after it.
    @Test
    func pauseEndedEarlyFreesTheFollowingWeeks() {
        let pause = WeeklyGoalPause(start: F.day(week: -2, hour: 0), plannedEnd: F.day(week: 2, hour: 0),
                                    endedAt: F.day(week: -2, 2))
        let entries = F.trained(week: -3, days: [0, 1, 2])
        #expect(verdict(-2, threeDays, pauses: [pause], entries: entries, asOf: F.day(1))?.status == .paused)
        #expect(verdict(-1, threeDays, pauses: [pause], entries: entries, asOf: F.day(1))?.status == .missed)
        #expect(streak(threeDays, pauses: [pause], entries: entries, asOf: F.day(1)) == 0)
    }

    // MARK: Nothing scheduled

    @Test
    func weekWithNothingScheduledIsNeutral() {
        let allScheduled = F.goal(.plannedWorkouts(target: .allScheduled))
        let versions = [F.version([allScheduled], from: F.day(week: -6, hour: 0))]
        // A one-off plan in week -2 is the only thing ever scheduled.
        let oneOff = WorkoutPlan(name: "Test", schedule: .once(F.day(week: -2), in: F.calendar), createdAt: F.day(week: -6))
        let entries = [F.entry(at: F.day(week: -2), plan: oneOff), F.entry(at: F.day(week: -1), plan: oneOff)]
        let now = F.day(1)

        #expect(verdict(-1, versions, entries: entries, plans: [oneOff], asOf: now)?.status == .nothingScheduled)
        #expect(verdict(-2, versions, entries: entries, plans: [oneOff], asOf: now)?.status == .met)
        #expect(streak(versions, entries: entries, plans: [oneOff], asOf: now) == 1)
    }
}

// MARK: - Snapshot

struct WeeklyGoalSnapshotTests {
    /// With nothing saved, the default (3 training days) applies from the
    /// first logged workout, so history earns a streak right away.
    @Test
    func implicitDefaultStartsAtTheFirstWorkout() throws {
        let entries = F.trained(week: -2, days: [0, 2, 4]) + F.trained(week: -1, days: [1, 3, 5])
            + F.trained(week: 0, days: [0])
        let snapshot = WeeklyGoalEvaluator.snapshot(history: .empty, entries: entries, plans: [],
                                                    calendar: F.calendar, asOf: F.day(1))
        #expect(snapshot.isDefault)
        #expect(snapshot.week.primary.goal == WeeklyGoal.defaultGoals[0])
        #expect(snapshot.week.primary.value == 1)
        #expect(snapshot.week.status == .inProgress)
        #expect(snapshot.streak == 2)
        #expect(snapshot.activePause == nil)
    }

    @Test
    func implicitDefaultFirstWeekFromThursdayIsAWarmUp() {
        let entries = F.trained(week: 0, days: [3])
        let snapshot = WeeklyGoalEvaluator.snapshot(history: .empty, entries: entries, plans: [],
                                                    calendar: F.calendar, asOf: F.day(4))
        #expect(snapshot.week.isWarmUp)
        #expect(snapshot.week.status == .warmUp)
    }

    @Test
    func emptyJournalShowsTheDefaultAtZero() {
        let snapshot = WeeklyGoalEvaluator.snapshot(history: .empty, entries: [], plans: [],
                                                    calendar: F.calendar, asOf: F.day(2))
        #expect(snapshot.week.primary.value == 0)
        #expect(snapshot.week.primary.target == WeeklyGoal.defaultTrainingDays)
        #expect(snapshot.streak == 0)
    }

    @Test
    func metGoalsWaitForTheirCelebrationOnce() {
        let volume = F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 8))
        let history = WeeklyGoalHistory(versions: [F.version([F.days(3), volume], from: F.day(week: -3, hour: 0))])
        let entries = F.trained(week: 0, days: [0])

        let before = WeeklyGoalEvaluator.snapshot(history: history, entries: entries, plans: [],
                                                  calendar: F.calendar, asOf: F.day(1))
        #expect(before.pendingCelebrations.map(\.goal) == [volume])

        let marked = history.markingCelebrated(goalID: volume.id, weekStart: F.monday, calendar: F.calendar)
        let after = WeeklyGoalEvaluator.snapshot(history: marked, entries: entries, plans: [],
                                                 calendar: F.calendar, asOf: F.day(1))
        #expect(after.pendingCelebrations.isEmpty)

        let nextWeek = WeeklyGoalEvaluator.snapshot(history: marked, entries: entries + F.trained(week: 1, days: [0]),
                                                    plans: [], calendar: F.calendar, asOf: F.day(week: 1, 1))
        #expect(nextWeek.pendingCelebrations.map(\.goal) == [volume])
    }

    @Test
    func activePauseIsReported() {
        let pause = WeeklyGoalPause(start: F.day(0, hour: 0), plannedEnd: F.day(7, hour: 0))
        let history = WeeklyGoalHistory(pauses: [pause])
        let snapshot = WeeklyGoalEvaluator.snapshot(history: history, entries: [], plans: [],
                                                    calendar: F.calendar, asOf: F.day(2))
        #expect(snapshot.activePause == pause)
        #expect(snapshot.week.status == .paused)
    }
}
