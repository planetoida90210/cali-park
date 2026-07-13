import Foundation

// MARK: - WorkoutLogEntry
/// One logged workout for a single exercise: a date plus the sets performed.
/// References the exercise by `exerciseID` (stable UUID from `ExerciseCatalog`).
struct WorkoutLogEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var exerciseID: UUID
    var date: Date
    var sets: [LoggedSet]
    var note: String?

    init(id: UUID = UUID(),
         exerciseID: UUID,
         date: Date = .now,
         sets: [LoggedSet],
         note: String? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.date = date
        self.sets = sets
        self.note = note
    }

    /// Total repetitions across all sets.
    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
