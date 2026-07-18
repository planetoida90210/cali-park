import Foundation

// MARK: - ExerciseMeasurement
/// How a single set of an exercise is measured.
///
/// Dynamic movements (pull-ups, push-ups) count repetitions; isometric holds
/// (planks, levers) count the number of seconds the position is held. The
/// SetPad and history read this to label a set as reps or seconds.
///
/// Raw values are stable storage keys; the type is `Codable` so it can be
/// embedded in the built-in catalog and decoded with a `.reps` default for
/// entries encoded before this field existed.
enum ExerciseMeasurement: String, Codable, CaseIterable, Sendable {
    /// Repetitions, e.g. "3 × 8".
    case reps
    /// Seconds held, e.g. "3 × 20 s".
    case seconds
}
