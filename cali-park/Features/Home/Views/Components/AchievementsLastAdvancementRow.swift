import SwiftUI

// MARK: - AchievementsLastAdvancementRow
/// The most recent conquered rung, or a nudge to conquer the first one.
struct AchievementsLastAdvancementRow: View {
    /// `nil` before the first conquered rung.
    let advancement: HomeAchievementsSummary.Advancement?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ostatni awans")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            if let advancement {
                HStack(spacing: 12) {
                    Image(systemName: advancement.symbolName)
                        .font(.appTitle3)
                        .foregroundStyle(Color.accent)
                        .scaledIconFrame(40, relativeTo: .title3)
                        .background(Color.accent.opacity(0.15))
                        .clipShape(.circle)
                        .accessibilityHidden(true)

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
