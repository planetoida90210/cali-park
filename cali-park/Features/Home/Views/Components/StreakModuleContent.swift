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
