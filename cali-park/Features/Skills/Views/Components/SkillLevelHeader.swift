import SwiftUI

// MARK: - SkillLevelHeader
/// Level and XP progress. Numbers animate on change so a fresh workout reads as
/// forward motion.
struct SkillLevelHeader: View {
    let level: PlayerLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Poziom \(level.level)")
                .font(.appTitle)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)

            ProgressView(value: level.progressToNextLevel)
                .tint(Color.accent)

            Text("\(level.xpToNextLevel) XP do poziomu \(level.level + 1)")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Poziom \(level.level)")
        .accessibilityValue("\(level.xpToNextLevel) XP do poziomu \(level.level + 1)")
    }
}
