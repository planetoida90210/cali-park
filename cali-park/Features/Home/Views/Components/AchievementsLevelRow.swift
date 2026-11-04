import SwiftUI

// MARK: - AchievementsLevelRow
/// The athlete's level, with earned badges out of all badges on the right.
struct AchievementsLevelRow: View {
    let summary: HomeAchievementsSummary

    var body: some View {
        HStack {
            Text("Poziom \(summary.level)")
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Spacer()

            Text("\(summary.earnedBadgeCount)/\(summary.totalBadgeCount)")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .accessibilityLabel("Zdobyte odznaki: \(summary.earnedBadgeCount) z \(summary.totalBadgeCount)")
        }
    }
}
