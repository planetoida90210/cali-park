import Foundation

// MARK: - ExerciseCategory
/// Difficulty tier of an exercise. Raw values are stable storage keys;
/// user-facing text comes from `displayName`. Order of cases defines
/// the progression (used for sorting and filter chips).
nonisolated enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case basic
    case advanced
    case expert

    var id: String { rawValue }

    /// Polish name shown in the UI.
    var displayName: String {
        switch self {
        case .basic: String(localized: "Podstawowe")
        case .advanced: String(localized: "Zaawansowane")
        case .expert: String(localized: "Ekspert")
        }
    }
}
