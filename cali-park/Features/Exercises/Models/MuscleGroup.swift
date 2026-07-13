import Foundation

// MARK: - MuscleGroup
/// Muscle groups targeted by calisthenics exercises. Raw values are stable
/// storage keys; user-facing text comes from `displayName`.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case back
    case chest
    case shoulders
    case arms
    case core
    case legs

    var id: String { rawValue }

    /// Polish name shown in the UI.
    var displayName: String {
        switch self {
        case .back: "Plecy"
        case .chest: "Klatka"
        case .shoulders: "Barki"
        case .arms: "Ramiona"
        case .core: "Core"
        case .legs: "Nogi"
        }
    }
}
