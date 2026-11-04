import SwiftUI

// MARK: - ProfileStatisticsGrid
/// Four tiles: workouts, day streak, week streak, level with XP progress.
struct ProfileStatisticsGrid: View {
    let statistics: ProfileStatistics

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            // Half-width tiles can't hold accessibility text sizes: one per row.
            VStack(spacing: 12) {
                workoutsTile
                dayStreakTile
                weekStreakTile
                ProfileLevelTile(level: statistics.level)
            }
        } else {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    workoutsTile
                    dayStreakTile
                }
                GridRow {
                    weekStreakTile
                    ProfileLevelTile(level: statistics.level)
                }
            }
        }
    }

    private var workoutsTile: some View {
        tile(
            value: "\(statistics.workouts)",
            caption: PolishPlural.form(for: statistics.workouts, one: "trening", few: "treningi", many: "treningów"),
            systemImage: "figure.strengthtraining.functional")
    }

    private var dayStreakTile: some View {
        tile(
            value: "\(statistics.dayStreak)",
            caption: String(localized: "seria dni · rekord \(statistics.longestDayStreak)"),
            systemImage: "flame.fill")
    }

    private var weekStreakTile: some View {
        tile(
            value: statistics.weekStreak.map(String.init) ?? "–",
            caption: String(localized: "seria tygodni z celem"),
            systemImage: "calendar")
    }

    private func tile(value: String, caption: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.appTitle)
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
            Text(caption)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        // Fills the grid cell, so both tiles in a row share one height.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}
