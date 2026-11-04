import SwiftUI

// MARK: - StreakSummaryRow
/// The current streak in days, with the longest streak on the right.
struct StreakSummaryRow: View {
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
