import Foundation

// MARK: - Badge
/// A statically defined achievement, awarded strictly from real logs.
///
/// Definitions (title, requirement, symbol) live here; whether each is earned is
/// computed by `ProgressionEngine.earnedBadges(from:)`. Declarations never grant
/// a badge — there are no rewards for clicking, only for training. Raw values
/// are stable storage keys.
nonisolated enum Badge: String, Codable, CaseIterable, Identifiable, Sendable {
    /// First workout ever logged.
    case firstWorkout
    /// Trained on at least ten distinct days.
    case tenTrainingDays
    /// Reached a streak of seven consecutive days.
    case weekStreak
    /// Conquered every rung of at least one path.
    case firstSkill
    /// Conquered three whole paths.
    case threeSkills
    /// Logged a thousand repetitions in total.
    case thousandReps

    var id: String { rawValue }

    /// Short Polish title for the badge.
    var title: String {
        switch self {
        case .firstWorkout: String(localized: "Pierwszy trening")
        case .tenTrainingDays: String(localized: "Regularność")
        case .weekStreak: String(localized: "Tydzień z rzędu")
        case .firstSkill: String(localized: "Pierwsza ścieżka")
        case .threeSkills: String(localized: "Kolekcjoner")
        case .thousandReps: String(localized: "Tysiąc powtórzeń")
        }
    }

    /// Plain-language requirement, shown on locked badges too.
    var requirement: String {
        switch self {
        case .firstWorkout: String(localized: "Zapisz pierwszy trening.")
        case .tenTrainingDays: String(localized: "Trenuj przez 10 różnych dni.")
        case .weekStreak: String(localized: "Trenuj 7 dni z rzędu.")
        case .firstSkill: String(localized: "Ukończ dowolną ścieżkę.")
        case .threeSkills: String(localized: "Ukończ trzy ścieżki.")
        case .thousandReps: String(localized: "Zbierz łącznie 1000 powtórzeń.")
        }
    }

    /// SF Symbol rendered in the Watch-Workout style used across the app.
    var symbolName: String {
        switch self {
        case .firstWorkout: "figure.strengthtraining.traditional"
        case .tenTrainingDays: "calendar"
        case .weekStreak: "flame.fill"
        case .firstSkill: "rosette"
        case .threeSkills: "medal.fill"
        case .thousandReps: "chart.bar.fill"
        }
    }
}
