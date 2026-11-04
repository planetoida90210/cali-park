import SwiftUI

// MARK: - AchievementsCard
/// The achievements module's card: level and badge count, XP bar, and the
/// most recent conquered rung.
struct AchievementsCard: View {
    let summary: HomeAchievementsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AchievementsLevelRow(summary: summary)
            AchievementsXPBar(summary: summary)
            AchievementsLastAdvancementRow(advancement: summary.lastAdvancement)
        }
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
    }
}
