import SwiftUI

// MARK: - StreakMonthCalendar
/// Days of the current month in Monday-first weeks; trained days get an
/// accent dot. The layout comes from `StreakMonthGrid`.
struct StreakMonthCalendar: View {
    let trainedDays: Set<Date>
    let today: Date
    let calendar: Calendar

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        let grid = StreakMonthGrid(month: today, calendar: calendar)

        VStack(spacing: 8) {
            Text(today, format: .dateTime.month(.wide).year())
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(StreakMonthGrid.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityHidden(true)
                }

                ForEach(grid.cells.indices, id: \.self) { index in
                    if let day = grid.cells[index] {
                        StreakDayCell(
                            dayNumber: calendar.component(.day, from: day),
                            isTrained: trainedDays.contains(day),
                            isToday: calendar.isDate(day, inSameDayAs: today)
                        )
                    } else {
                        Color.clear
                            .scaledIconFrame(28, relativeTo: .caption)
                            .accessibilityHidden(true)
                    }
                }
            }
            // Seven columns must fit the width: the weekday letters and day
            // numbers stop growing at XXXL.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
