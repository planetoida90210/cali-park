//
//  StreakMonthGridTests.swift
//  cali-parkTests
//
//  The "Seria dni" month grid: Monday-first weeks, day 1 under its weekday.
//

import Foundation
import Testing
@testable import cali_park

struct StreakMonthGridTests {
    /// A gregorian UTC calendar that starts weeks on Sunday, as in the US, to
    /// show the grid does not follow the locale's first weekday.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 1
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Self.calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    @Test
    func headerIsPolishMondayFirst() {
        #expect(StreakMonthGrid.weekdaySymbols == ["pn", "wt", "śr", "cz", "pt", "sb", "nd"])
    }

    /// 1 November 2026 is a Sunday: six blanks, then day 1 in the last column.
    @Test
    func dayOneSitsUnderItsWeekday() throws {
        let grid = StreakMonthGrid(month: try date(2026, 11, 4), calendar: Self.calendar)

        #expect(grid.cells.prefix(6).allSatisfy { $0 == nil })
        #expect(grid.cells[6] == (try date(2026, 11, 1)))
        #expect(grid.cells[7] == (try date(2026, 11, 2)))
    }

    /// June 2026 starts on a Monday: no leading blanks.
    @Test
    func monthStartingOnMondayHasNoLeadingBlanks() throws {
        let grid = StreakMonthGrid(month: try date(2026, 6, 15), calendar: Self.calendar)
        #expect(grid.cells.first == (try date(2026, 6, 1)))
    }

    @Test(arguments: [(2026, 2), (2026, 11), (2026, 6), (2024, 2)])
    func gridFillsWholeWeeksAndHoldsEveryDay(year: Int, month: Int) throws {
        let grid = StreakMonthGrid(month: try date(year, month, 10), calendar: Self.calendar)
        let days = grid.cells.compactMap { $0 }
        let dayCount = try #require(Self.calendar.range(of: .day, in: .month, for: try date(year, month, 1))?.count)

        #expect(grid.cells.count.isMultiple(of: 7))
        #expect(days.count == dayCount)
        #expect(days.first == (try date(year, month, 1)))
        #expect(days.map { Self.calendar.component(.day, from: $0) } == Array(1...dayCount))
        // Every day sits in the column of its weekday (Monday = column 0).
        for (index, cell) in grid.cells.enumerated() {
            guard let cell else { continue }
            let mondayFirst = (Self.calendar.component(.weekday, from: cell) + 5) % 7
            #expect(index % 7 == mondayFirst)
        }
    }
}
