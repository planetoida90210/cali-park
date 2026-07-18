import Foundation

// MARK: - RepCountBucket
/// A bucketed self-report of how many clean reps the athlete manages in a single
/// set, used to place them on a rep-based ladder during onboarding and
/// calibration.
///
/// Buckets are deliberately coarse — a newcomer and a veteran both answer in one
/// tap. This is transient UI input, never persisted: only the resulting rung
/// index is stored in `SkillPlacement`.
enum RepCountBucket: String, CaseIterable, Identifiable, Hashable, Sendable {
    case none
    case few
    case several
    case many

    var id: String { rawValue }

    /// Short, concrete label with real numbers, e.g. "1–4".
    var label: String {
        switch self {
        case .none: "0"
        case .few: "1–4"
        case .several: "5–8"
        case .many: "9+"
        }
    }
}
