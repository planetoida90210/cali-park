import Foundation

// MARK: - Badge
/// A statically defined achievement, awarded strictly from real logs.
///
/// Definitions (title, requirement, symbol) live here; whether each is earned is
/// computed by `ProgressionEngine.earnedBadges(from:)`. Declarations never grant
/// a badge — there are no rewards for clicking, only for training. Raw values
/// are stable storage keys.
enum Badge: String, Codable, CaseIterable, Identifiable, Sendable {
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
        case .firstWorkout: "Pierwszy trening"
        case .tenTrainingDays: "Regularność"
        case .weekStreak: "Tydzień z rzędu"
        case .firstSkill: "Pierwszy skill"
        case .threeSkills: "Kolekcjoner"
        case .thousandReps: "Tysiąc powtórzeń"
        }
    }

    /// Plain-language requirement, shown on locked badges too.
    var requirement: String {
        switch self {
        case .firstWorkout: "Zapisz pierwszy trening."
        case .tenTrainingDays: "Trenuj przez 10 różnych dni."
        case .weekStreak: "Trenuj 7 dni z rzędu."
        case .firstSkill: "Ukończ dowolną ścieżkę."
        case .threeSkills: "Ukończ trzy ścieżki."
        case .thousandReps: "Zbierz łącznie 1000 powtórzeń."
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
