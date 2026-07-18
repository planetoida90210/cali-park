import Foundation

// MARK: - AdvancementCriterion
/// The performance target that marks a progression step as conquered.
///
/// Criteria come straight from the source routines: dynamic movements advance
/// on clean sets of reps (Recommended Routine's "3 × 8 → next"), isometric
/// holds on clean sets of seconds (Overcoming Gravity's "3 × 20 s → next").
/// The engine (SK3) compares logged sets against this to score progress.
enum AdvancementCriterion: Codable, Equatable, Hashable, Sendable {
    /// A number of clean sets at a rep count, e.g. `sets: 3, reps: 8`.
    case setsOfReps(sets: Int, reps: Int)
    /// A number of clean sets holding a position, e.g. `sets: 3, seconds: 20`.
    case setsOfHold(sets: Int, seconds: Int)

    /// The number of sets the criterion asks for, regardless of kind.
    var sets: Int {
        switch self {
        case let .setsOfReps(sets, _), let .setsOfHold(sets, _): sets
        }
    }

    /// The measurement the criterion is scored in. A step's exercise must use
    /// the matching `ExerciseMeasurement` (reps criteria on rep movements,
    /// hold criteria on second-based holds).
    var measurement: ExerciseMeasurement {
        switch self {
        case .setsOfReps: .reps
        case .setsOfHold: .seconds
        }
    }
}
