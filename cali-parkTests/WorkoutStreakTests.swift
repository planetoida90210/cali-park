//
//  WorkoutStreakTests.swift
//  cali-parkTests
//
//  Sprint 4 — streak math (today, yesterday, gap) and day plurals.
//

import Foundation
import Testing
@testable import cali_park

struct WorkoutStreakTests {
    /// Fixed clock so results never depend on when the tests run.
    /// "Today" is day 100 of a UTC calendar.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private static let today = Date(timeIntervalSince1970: 100 * 86_400 + 12 * 3_600)

    /// A date `offset` days before the fixed today (0 = today, 1 = yesterday…).
    private static func daysAgo(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: -offset, to: today)!
    }

    @Test(arguments: [
        // (workout day offsets, expected current, expected longest)
        // trained today and the two days before — streak of 3
        ([0, 1, 2], 3, 3),
        // not yet today, but yesterday — streak survives
        ([1, 2, 3], 3, 3),
        // last workout two days ago — streak is broken
        ([2, 3, 4], 0, 3),
        // gap in the middle: current run counts from today only
        ([0, 1, 3, 4, 5], 2, 3),
        // single workout today
        ([0], 1, 1),
        // single workout long ago
        ([30], 0, 1),
        // empty journal
        ([], 0, 0),
        // two entries on the same day count as one streak day
        ([0, 0, 1], 2, 2)
    ])
    func streakRuns(offsets: [Int], current: Int, longest: Int) {
        let dates = offsets.map(Self.daysAgo)
        let streak = WorkoutStreak.compute(from: dates, calendar: Self.calendar, today: Self.today)

        #expect(streak.current == current)
        #expect(streak.longest == longest)
    }

    @Test
    func trainedDaysAreNormalizedToStartOfDay() {
        let morning = Self.daysAgo(0)
        let evening = Self.calendar.date(byAdding: .hour, value: 8, to: morning)!
        let streak = WorkoutStreak.compute(from: [morning, evening],
                                           calendar: Self.calendar,
                                           today: Self.today)

        #expect(streak.trainedDays.count == 1)
        #expect(streak.trainedDays.first == Self.calendar.startOfDay(for: morning))
    }
}

// MARK: - PolishPlural (days, pull-ups)

struct PolishPluralHomeTests {
    @Test(arguments: [
        (0, "0 dni"),
        (1, "1 dzień"),
        (2, "2 dni"),
        (5, "5 dni"),
        (12, "12 dni"),
        (22, "22 dni")
    ])
    func dayForms(count: Int, expected: String) {
        #expect(PolishPlural.days(count) == expected)
    }

    @Test(arguments: [
        (1, "1 podciągnięcie"),
        (3, "3 podciągnięcia"),
        (5, "5 podciągnięć"),
        (13, "13 podciągnięć"),
        (22, "22 podciągnięcia"),
        (57, "57 podciągnięć")
    ])
    func pullUpForms(count: Int, expected: String) {
        #expect(PolishPlural.pullUps(count) == expected)
    }
}
