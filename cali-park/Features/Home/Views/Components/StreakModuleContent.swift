import SwiftUI

// MARK: - Streak Module
/// Streak and this month's training calendar, computed from workout log dates.
struct StreakModuleContent: View {
    let streak: WorkoutStreak

    var body: some View {
        VStack(spacing: 16) {
            if streak.trainedDays.isEmpty {
                StreakEmptyState()
            } else {
                StreakSummaryRow(streak: streak)
                StreakMonthCalendar(trainedDays: streak.trainedDays)
            }
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - StreakSummaryRow
private struct StreakSummaryRow: View {
    let streak: WorkoutStreak

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak.current > 0 ? Color.orange : Color.textSecondary)
                .font(.title)

            VStack(alignment: .leading, spacing: 2) {
                Text(PolishPlural.days(streak.current))
                    .font(.title3)
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())

                Text("aktualny streak")
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
/// Days of the current month; trained days get an accent dot.
private struct StreakMonthCalendar: View {
    let trainedDays: Set<Date>

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            Text(Date.now, format: .dateTime.month(.wide).year())
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(daysInCurrentMonth, id: \.self) { day in
                    StreakDayCell(
                        dayNumber: calendar.component(.day, from: day),
                        isTrained: trainedDays.contains(day),
                        isToday: calendar.isDateInToday(day)
                    )
                }
            }
        }
    }

    private var daysInCurrentMonth: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: .now),
              let dayCount = calendar.range(of: .day, in: .month, for: .now)?.count
        else { return [] }

        return (0..<dayCount).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
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
                .frame(width: 28, height: 28)

            if isToday {
                Circle()
                    .stroke(Color.accent, lineWidth: 1)
                    .frame(width: 28, height: 28)
            }

            Text("\(dayNumber)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
        }
        .accessibilityLabel(isTrained ? "\(dayNumber), trening zaliczony" : "\(dayNumber)")
    }
}

// MARK: - StreakEmptyState
private struct StreakEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.title2)
                .foregroundStyle(Color.textSecondary)

            Text("Brak streaka")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zaloguj trening, aby zacząć serię dni.")
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
