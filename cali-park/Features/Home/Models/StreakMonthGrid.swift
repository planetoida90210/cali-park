import Foundation

// MARK: - StreakMonthGrid
/// The "Seria dni" month grid: weeks start on Monday (as in Poland and in the
/// weekly goal), so day 1 sits under its weekday and the cells before it are
/// blank. A pure value built from the reference day and the calendar.
nonisolated struct StreakMonthGrid: Equatable {
    /// The weekday header, Monday first.
    static let weekdaySymbols = ["pn", "wt", "śr", "cz", "pt", "sb", "nd"]

    /// Row-major cells, seven per week. `nil` is a blank before day 1 or after
    /// the last day; a date is the start of that day in the calendar.
    let cells: [Date?]

    /// The grid of the month that contains `today`.
    init(month today: Date, calendar: Calendar) {
        guard let interval = calendar.dateInterval(of: .month, for: today),
              let dayCount = calendar.range(of: .day, in: .month, for: today)?.count
        else {
            cells = []
            return
        }

        let days: [Date?] = (0..<dayCount).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
        // Gregorian weekday: 1 = Sunday … 7 = Saturday. Monday-first offset 0…6.
        let leading = (calendar.component(.weekday, from: interval.start) + 5) % 7
        let trailing = (7 - (leading + days.count) % 7) % 7
        cells = Array(repeating: nil, count: leading) + days + Array(repeating: nil, count: trailing)
    }
}
