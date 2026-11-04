import Foundation

// MARK: - MuscleGroup
/// Muscle groups targeted by calisthenics exercises. Raw values are stable
/// storage keys; user-facing text comes from `displayName`.
nonisolated enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
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
        case .back: String(localized: "Plecy")
        case .chest: String(localized: "Klatka")
        case .shoulders: String(localized: "Barki")
        case .arms: String(localized: "Ramiona")
        case .core: String(localized: "Core", comment: "Muscle group: core (abdominals and lower back)")
        case .legs: String(localized: "Nogi")
        }
    }
}
