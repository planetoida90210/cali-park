import Foundation

// MARK: - LoggedSet
/// One set inside a workout log entry.
///
/// A set is measured either in repetitions or in seconds held. `reps` carries
/// the count for a rep-based set; `durationSeconds` carries the held time for an
/// isometric set (plank, lever) and, for such a set, `reps` stands at 1 as a
/// technical marker that a single hold happened. `durationSeconds` is optional
/// and decodes to `nil` for logs saved before timed sets existed, so old data
/// stays valid — exactly like `WorkoutLogEntry.sessionID`.
///
/// `weight` (kg) stays optional — the SetPad logs bodyweight sets for now, but
/// the model is ready for it.
struct LoggedSet: Codable, Equatable, Hashable {
    var reps: Int
    var weight: Double?
    /// Seconds held for an isometric set; `nil` for a rep-based set.
    var durationSeconds: Int?

    init(reps: Int, weight: Double? = nil, durationSeconds: Int? = nil) {
        self.reps = reps
        self.weight = weight
        self.durationSeconds = durationSeconds
    }

    /// Creates a set from one SetPad value, read as reps or seconds held per
    /// `measurement`. A timed set keeps `reps` at 1 — a technical marker that a
    /// single hold occurred — and stores the value in `durationSeconds`.
    init(value: Int, measurement: ExerciseMeasurement) {
        switch measurement {
        case .reps:
            self.init(reps: value)
        case .seconds:
            self.init(reps: 1, durationSeconds: value)
        }
    }

    /// Whether this set records a timed hold rather than repetitions.
    var isTimed: Bool { durationSeconds != nil }

    /// The value this set returns to the SetPad when re-editing, in the unit
    /// implied by `measurement`: a rep count, or the seconds held.
    func padValue(for measurement: ExerciseMeasurement) -> Int {
        switch measurement {
        case .reps: reps
        case .seconds: durationSeconds ?? reps
        }
    }
}
