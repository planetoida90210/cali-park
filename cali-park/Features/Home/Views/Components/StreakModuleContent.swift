import SwiftUI

// MARK: - Streak Module
/// Streak and this month's training calendar, computed from workout log dates.
struct StreakModuleContent: View {
    let streak: WorkoutStreak
    /// Reference day for the month grid and its "today" ring.
    var today: Date = .now
    var calendar: Calendar = .current

    var body: some View {
        VStack(spacing: 16) {
            if streak.trainedDays.isEmpty {
                StreakEmptyState()
            } else {
                StreakSummaryRow(streak: streak)
                StreakMonthCalendar(trainedDays: streak.trainedDays, today: today, calendar: calendar)
            }
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
    }
}

// MARK: - StreakSummaryRow
private struct StreakSummaryRow: View {
    let streak: WorkoutStreak

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak.current > 0 ? Color.streak : Color.textSecondary)
                .font(.title)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(PolishPlural.days(streak.current))
                    .font(.appTitle3)
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())

                Text("aktualna seria")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Rekord: \(PolishPlural.days(streak.longest))")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - StreakMonthCalendar
/// Days of the current month in Monday-first weeks; trained days get an
/// accent dot. The layout comes from `StreakMonthGrid`.
private struct StreakMonthCalendar: View {
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

// MARK: - StreakDayCell
private struct StreakDayCell: View {
    let dayNumber: Int
    let isTrained: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isTrained ? Color.accent.opacity(0.3) : Color.clear)

            if isToday {
                Circle()
                    .stroke(Color.accent, lineWidth: 1)
            }

            Text("\(dayNumber)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
        }
        .scaledIconFrame(28, relativeTo: .caption)
        .accessibilityLabel(isTrained ? String(localized: "\(dayNumber), trening zaliczony") : "\(dayNumber)")
    }
}

// MARK: - StreakEmptyState
private struct StreakEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.appTitle2)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)

            Text("Brak serii")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zaloguj trening, aby zacząć.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    StreakModuleContent(
        streak: WorkoutStreak.compute(from: [
            .now,
            Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        ])
    )
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
