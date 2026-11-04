import SwiftUI

// MARK: - AchievementsXPBar
/// Progress to the next level, with the XP still missing below the bar.
struct AchievementsXPBar: View {
    let summary: HomeAchievementsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: summary.progressToNextLevel)
                .tint(Color.accent)

            Text("\(summary.xpToNextLevel) XP do poziomu \(summary.level + 1)")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
        }
    }
}
