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
            content
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otwiera zakładkę Skille")
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            levelRow
            xpBar
            lastAdvancementRow
        }
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var levelRow: some View {
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

    private var xpBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: summary.progressToNextLevel)
                .tint(Color.accent)

            Text("\(summary.xpToNextLevel) XP do poziomu \(summary.level + 1)")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
        }
    }

    @ViewBuilder
    private var lastAdvancementRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ostatni awans")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            if let advancement = summary.lastAdvancement {
                HStack(spacing: 12) {
                    Image(systemName: advancement.symbolName)
                        .font(.title3)
                        .foregroundStyle(Color.accent)
                        .frame(width: 40, height: 40)
                        .background(Color.accent.opacity(0.15))
                        .clipShape(.circle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(advancement.title)
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textPrimary)

                        Text(advancement.pathName)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("Zalicz pierwszy szczebel, aby zdobyć awans.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
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
