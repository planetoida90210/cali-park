import SwiftUI

// MARK: - ProfileLevelTile
/// The statistics grid's level tile: the level, XP progress and the XP left
/// to the next level.
struct ProfileLevelTile: View {
    let level: PlayerLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text("Poziom \(level.level)")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
            ProgressView(value: level.progressToNextLevel)
                .tint(Color.accent)
            Text("\(level.totalXP) XP · \(level.xpToNextLevel) do następnego")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                // Wraps instead of truncating "do następnego" in the half-width tile.
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Poziom \(level.level), \(level.totalXP) XP, \(level.xpToNextLevel) XP do następnego poziomu")
    }
}
