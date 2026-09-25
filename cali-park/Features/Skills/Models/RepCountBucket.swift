import Foundation

// MARK: - RepCountBucket
/// A bucketed self-report of how many clean reps the athlete manages in a single
/// set, used to place them on a rep-based ladder during onboarding and
/// calibration.
///
/// Buckets are deliberately coarse — a newcomer and a veteran both answer in one
/// tap. The top bucket starts at 12 because a single-set max around 12 is what
/// three sets of 8 need; 9 in one set does not yet mean 3 × 8. This is
/// transient UI input, never persisted: only the resulting rung index is stored
/// in `SkillPlacement`.
enum RepCountBucket: String, CaseIterable, Identifiable, Hashable, Sendable {
    case none
    case few
    case several
    case many

    var id: String { rawValue }

    /// Short, concrete label with real numbers, e.g. "1–5".
    var label: String {
        switch self {
        case .none: "0"
        case .few: "1–5"
        case .several: "6–11"
        case .many: "12+"
        }
    }
}
