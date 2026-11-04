import Foundation
import Testing
@testable import cali_park

/// B-16: day math across the Europe/Warsaw clock changes (2026-03-29, when a
/// day has 23 hours, and 2026-10-25, when it has 25). Every other date suite
/// runs on UTC, which has no clock change.
struct DaylightSavingTests {
    private static let warsaw = TestCalendar.warsaw

    /// Local wall-clock time in Warsaw.
    private static func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) throws -> Date {
        try #require(warsaw.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
    }

    /// Both 2026 transition weekends: (Saturday, Sunday, Monday).
    static let transitions: [(Int, Int, Int, Int)] = [
        (3, 28, 29, 30),
        (10, 24, 25, 26)
    ]

    @Test(arguments: transitions)
    func aStreakSurvivesTheClockChange(month: Int, saturday: Int, sunday: Int, monday: Int) throws {
        let dates = [
            try Self.local(2026, month, saturday, 23, 30),
            try Self.local(2026, month, sunday, 0, 30),
            try Self.local(2026, month, monday, 6, 0)
        ]
        let streak = WorkoutStreak.compute(from: dates, calendar: Self.warsaw, today: try Self.local(2026, month, monday, 20))

        #expect(streak.current == 3)
        #expect(streak.longest == 3)
        #expect(streak.trainedDays.count == 3)
    }

    @Test(arguments: transitions)
    func aDailyPlanComesUpOnEveryDayOfTheWeekend(month: Int, saturday: Int, sunday: Int, monday: Int) throws {
        let schedule = WorkoutSchedule.everyNDays(1, from: CalendarDay(year: 2026, month: month, day: saturday)!)

        for day in [saturday, sunday, monday] {
            let next = schedule.nextOccurrence(onOrAfter: try Self.local(2026, month, day, 23, 59), calendar: Self.warsaw)
            #expect(next == Self.warsaw.startOfDay(for: try Self.local(2026, month, day)))
        }
    }

    @Test(arguments: transitions)
    func aSecondDayPlanSkipsTheTransitionSunday(month: Int, saturday: Int, sunday: Int, monday: Int) throws {
        let schedule = WorkoutSchedule.everyNDays(2, from: CalendarDay(year: 2026, month: month, day: saturday)!)

        let next = schedule.nextOccurrence(onOrAfter: try Self.local(2026, month, sunday, 1), calendar: Self.warsaw)

        #expect(next == Self.warsaw.startOfDay(for: try Self.local(2026, month, monday)))
    }

    @Test(arguments: transitions)
    func aSundayPlanLandsOnTheTransitionSunday(month: Int, saturday: Int, sunday: Int, monday: Int) throws {
        let schedule = WorkoutSchedule.weekly([.sunday])

        let next = schedule.nextOccurrence(onOrAfter: try Self.local(2026, month, saturday, 22), calendar: Self.warsaw)

        let expected = Self.warsaw.startOfDay(for: try Self.local(2026, month, sunday))
        #expect(next == expected)
        #expect(CalendarDay(try #require(next), in: Self.warsaw) == CalendarDay(year: 2026, month: month, day: sunday))
    }
}

// MARK: - Reminders at a wall-clock time the clock change skips or repeats

/// B-16: a 02:30 reminder in Warsaw. On 29 March 2026 the clock jumps from
/// 02:00 to 03:00, so 02:30 does not exist; on 25 October it goes back from
/// 03:00 to 02:00, so 02:30 happens twice. Either way the plan gets one
/// reminder that day, never none and never two.
struct DaylightSavingReminderTests {
    private static let warsaw = TestCalendar.warsaw

    private static func local(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        TestDate.at(2026, month, day, hour, minute, in: warsaw)
    }

    /// A daily plan from 20 March with a reminder at `hour:minute`.
    private static func dailyPlan(at hour: Int, _ minute: Int) -> WorkoutPlan {
        WorkoutPlan(name: "Nocny",
                    exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)],
                    schedule: .everyNDays(1, from: CalendarDay(year: 2026, month: 3, day: 20)!),
                    createdAt: TestDate.at(2026, 3, 1),
                    reminderTime: DateComponents(hour: hour, minute: minute))
    }

    /// The `(month, day)` of each request, in order.
    private static func days(_ requests: [WorkoutReminderRequest]) -> [[Int?]] {
        requests.map { [$0.dateComponents.month, $0.dateComponents.day] }
    }

    @Test
    func theSpringForwardNightStillGetsItsReminder() {
        let requests = WorkoutReminderPlanner.requests(for: Self.dailyPlan(at: 2, 30), calendar: Self.warsaw,
                                                       asOf: Self.local(3, 27, 12), limit: 4)

        #expect(Self.days(requests) == [[3, 28], [3, 29], [3, 30], [3, 31]])
        #expect(requests.allSatisfy { $0.dateComponents.hour == 2 && $0.dateComponents.minute == 30 })
        #expect(Set(requests.map(\.id)).count == 4)
    }

    @Test
    func justBeforeTheJumpTheReminderIsStillAhead() {
        let requests = WorkoutReminderPlanner.requests(for: Self.dailyPlan(at: 2, 30), calendar: Self.warsaw,
                                                       asOf: Self.local(3, 29, 1, 59), limit: 2)

        #expect(Self.days(requests) == [[3, 29], [3, 30]])
    }

    @Test
    func theFallBackNightGetsOneReminder() {
        let requests = WorkoutReminderPlanner.requests(for: Self.dailyPlan(at: 2, 30), calendar: Self.warsaw,
                                                       asOf: Self.local(10, 24, 12), limit: 3)

        #expect(Self.days(requests) == [[10, 25], [10, 26], [10, 27]])
        #expect(Set(requests.map(\.id)).count == 3)
    }

    /// Between the first 02:30 (00:30 UTC) and the repeated one (01:30 UTC),
    /// that day's reminder already fired, so a sync then must not schedule it
    /// again for the repeated 02:30.
    @Test
    func aSyncBetweenTheTwo0230sDoesNotRemindTwice() throws {
        let betweenThem = try #require(TestCalendar.utc.date(from: DateComponents(year: 2026, month: 10, day: 25,
                                                                                  hour: 1, minute: 0)))
        #expect(Self.warsaw.component(.hour, from: betweenThem) == 2) // 02:00 CET, the second time round

        let requests = WorkoutReminderPlanner.requests(for: Self.dailyPlan(at: 2, 30), calendar: Self.warsaw,
                                                       asOf: betweenThem, limit: 2)

        #expect(Self.days(requests) == [[10, 26], [10, 27]])
    }

    @Test(arguments: [(3, 28), (10, 24)])
    func anEveningReminderKeepsItsLocalTimeAcrossTheChange(month: Int, saturday: Int) throws {
        let requests = WorkoutReminderPlanner.requests(for: Self.dailyPlan(at: 18, 30), calendar: Self.warsaw,
                                                       asOf: Self.local(month, saturday, 12), limit: 3)

        #expect(Self.days(requests) == [[month, saturday], [month, saturday + 1], [month, saturday + 2]])
        for request in requests {
            let fire = try #require(Self.warsaw.date(from: request.dateComponents))
            #expect(Self.warsaw.dateComponents([.hour, .minute], from: fire) == DateComponents(hour: 18, minute: 30))
        }
    }
}

// MARK: - Weekly goal weeks across the clock change

/// B-16: a goal week runs Monday 00:00 to Monday 00:00 local time, so the week
/// with the spring change lasts 167 hours and the autumn one 169.
struct DaylightSavingWeeklyGoalTests {
    private typealias F = WeeklyGoalFixtures
    private static let warsaw = TestCalendar.warsaw

    private static func local(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        TestDate.at(2026, month, day, hour, minute, in: warsaw)
    }

    /// (month, Monday before the change, Sunday of the change, Monday after, hours in the week)
    static let weeks: [(Int, Int, Int, Int, Int)] = [
        (3, 23, 29, 30, 167),
        (10, 19, 25, 26, 169)
    ]

    @Test(arguments: weeks)
    func theWeekEndsAtMidnightBeforeMonday(month: Int, monday: Int, sunday: Int, nextMonday: Int, hours: Int) {
        let week = WeeklyGoalEvaluator.week(containing: Self.local(month, sunday, 23, 30), calendar: Self.warsaw)

        #expect(week.start == Self.local(month, monday, 0))
        #expect(week.end == Self.local(month, nextMonday, 0))
        #expect(week.duration == TimeInterval(hours * 3_600))
        #expect(WeeklyGoalEvaluator.week(containing: Self.local(month, nextMonday, 0, 30), calendar: Self.warsaw).start
                == week.end)
        #expect(WeeklyGoalEvaluator.week(before: WeeklyGoalEvaluator.week(containing: Self.local(month, nextMonday, 12),
                                                                          calendar: Self.warsaw),
                                         calendar: Self.warsaw) == week)
    }

    @Test(arguments: weeks)
    func workoutsCountInTheWeekOfTheirLocalDay(month: Int, monday: Int, sunday: Int, nextMonday: Int, hours: Int) {
        let entries = [
            F.entry(at: Self.local(month, sunday - 1, 23, 30)),
            F.entry(at: Self.local(month, sunday, 3, 30)),
            F.entry(at: Self.local(month, sunday, 23, 30)),
            F.entry(at: Self.local(month, nextMonday, 0, 30))
        ]
        let week = WeeklyGoalEvaluator.week(containing: Self.local(month, sunday, 12), calendar: Self.warsaw)
        let next = WeeklyGoalEvaluator.week(containing: Self.local(month, nextMonday, 12), calendar: Self.warsaw)

        let thisWeek = WeeklyGoalEvaluator.progress(of: F.days(3), in: week, entries: entries, plans: [], calendar: Self.warsaw)
        let nextWeek = WeeklyGoalEvaluator.progress(of: F.days(3), in: next, entries: entries, plans: [], calendar: Self.warsaw)

        #expect(thisWeek.value == 2) // Saturday and Sunday
        #expect(nextWeek.value == 1)
    }

    @Test(arguments: weeks)
    func theWeekStreakRunsThroughTheChange(month: Int, monday: Int, sunday: Int, nextMonday: Int, hours: Int) {
        // One workout on the Sunday of the week before, of the change week
        // and of the week after; a one-day goal set two weeks before.
        let entries = [-7, 0, 7].map { F.entry(at: Self.local(month, sunday, 20).addingTimeInterval(Double($0) * 86_400)) }
        let versions = [F.version([F.days(1)], from: Self.local(month, monday - 7, 0))]

        let streak = WeeklyGoalEvaluator.streak(versions: versions, pauses: [], entries: entries, plans: [],
                                                calendar: Self.warsaw, asOf: Self.local(month, nextMonday + 6, 22))

        #expect(streak == 3)
    }
}
