import Foundation
import Testing
@testable import cali_park

/// B-16: day math across the Europe/Warsaw clock changes (2026-03-29, when a
/// day has 23 hours, and 2026-10-25, when it has 25). Every other date suite
/// runs on UTC, which has no clock change.
struct DaylightSavingTests {
    private static let warsaw: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        return calendar
    }()

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
