import Foundation

// MARK: - CelebrationPresentation: weekly goal
nonisolated extension CelebrationPresentation {
    /// The overlay copy for a weekly goal reached this week. No XP: XP stays
    /// with conquered rungs, so it cannot be farmed with easy goals.
    static func weeklyGoalMet(_ progress: WeeklyGoalProgress, isPrimary: Bool, streak: Int) -> CelebrationPresentation {
        let title = WeeklyGoalFormat.title(progress.goal.metric)
        let subtitle = isPrimary && streak > 0 ? WeeklyGoalFormat.streak(streak) : nil
        let spokenTitle = WeeklyGoalFormat.spokenTitle(progress.goal.metric)
        let accessibilityLabel = if let subtitle {
            String(localized: "Cel tygodniowy wykonany: \(spokenTitle). \(subtitle).")
        } else {
            String(localized: "Cel tygodniowy wykonany: \(spokenTitle).")
        }
        return CelebrationPresentation(
            eyebrow: String(localized: "CEL TYGODNIOWY WYKONANY"),
            title: title,
            subtitle: subtitle,
            xpNote: nil,
            symbolName: "target",
            accessibilityLabel: accessibilityLabel
        )
    }
}
