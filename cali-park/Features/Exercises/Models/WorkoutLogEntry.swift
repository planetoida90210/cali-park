import Foundation

// MARK: - WorkoutLogEntry
/// One logged workout for a single exercise: a date plus the sets performed.
/// References the exercise by `exerciseID` (stable UUID from `ExerciseCatalog`).
///
/// A `sessionID` ties together the exercises logged in one "Szybki trening"
/// (quick workout) session. It is optional and decodes to `nil` for entries
/// saved before sessions existed, so old logs stay valid.
struct WorkoutLogEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var exerciseID: UUID
    var date: Date
    var sets: [LoggedSet]
    var note: String?
    /// Groups the exercises of one quick-workout session; `nil` for a
    /// standalone single-exercise log.
    var sessionID: UUID?

    init(id: UUID = UUID(),
         exerciseID: UUID,
         date: Date = .now,
         sets: [LoggedSet],
         note: String? = nil,
         sessionID: UUID? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.date = date
        self.sets = sets
        self.note = note
        self.sessionID = sessionID
    }

    /// Total repetitions across all sets.
    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
