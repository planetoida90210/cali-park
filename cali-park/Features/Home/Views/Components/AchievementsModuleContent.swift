import SwiftUI

// MARK: - Achievements Module
/// Home glance at the athlete's progression: level, XP to the next level, badge
/// count, and the most recent conquered rung — all real, from the same logs the
/// Skills tab reads. Tapping the card opens the Skills tab, where the full
/// ladders, XP, and badges live.
struct AchievementsModuleContent: View {
    /// Derived from `HomeDashboardViewModel`, so this view stays dumb.
    let summary: HomeAchievementsSummary

    /// Optional so previews (and any host without a router) render safely.
    @Environment(TabRouter.self) private var router: TabRouter?

    var body: some View {
        Button {
            router?.selection = .skills
        } label: {
            AchievementsCard(summary: summary)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otwiera zakładkę Ścieżki")
    }
}

// MARK: - Preview
#Preview("Z awansem") {
    AchievementsModuleContent(
        summary: HomeAchievementsSummary(
            level: 4,
            xpToNextLevel: 320,
            progressToNextLevel: 0.65,
            earnedBadgeCount: 3,
            totalBadgeCount: Badge.allCases.count,
            lastAdvancement: HomeAchievementsSummary.Advancement(
                title: "Pełne podciągnięcia",
                pathName: "Podciąganie",
                symbolName: "figure.climbing"
            )
        )
    )
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("Świeży start") {
    AchievementsModuleContent(
        summary: HomeAchievementsSummary(
            level: 1,
            xpToNextLevel: 500,
            progressToNextLevel: 0,
            earnedBadgeCount: 0,
            totalBadgeCount: Badge.allCases.count,
            lastAdvancement: nil
        )
    )
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
