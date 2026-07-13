import Foundation

// MARK: - ExerciseCategory
/// Difficulty tier of an exercise. Raw values are stable storage keys;
/// user-facing text comes from `displayName`. Order of cases defines
/// the progression (used for sorting and filter chips).
enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case basic
    case advanced
    case expert

    var id: String { rawValue }

    /// Polish name shown in the UI.
    var displayName: String {
        switch self {
        case .basic: "Podstawowe"
        case .advanced: "Zaawansowane"
        case .expert: "Ekspert"
        }
    }
}
