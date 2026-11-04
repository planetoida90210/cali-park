import Foundation

// MARK: - WorkoutLogEntry
/// One logged workout for a single exercise: a date plus the sets performed.
/// References the exercise by `exerciseID` (stable UUID from `ExerciseCatalog`).
///
/// A `sessionID` ties together the exercises logged in one "Szybki trening"
/// (quick workout) session. It is optional and decodes to `nil` for entries
/// saved before sessions existed, so old logs stay valid.
///
/// A `planID` records that the entry was logged from a specific `WorkoutPlan`,
/// letting Home tell precisely that *today's plan* was completed (not merely
/// that something was logged today). Optional and backward compatible: the
/// synthesized `Codable` decodes it to `nil` for entries saved before plans
/// stamped their sessions, exactly like `sessionID`.
nonisolated struct WorkoutLogEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var exerciseID: UUID
    var date: Date
    var sets: [LoggedSet]
    var note: String?
    /// Groups the exercises of one quick-workout session; `nil` for a
    /// standalone single-exercise log.
    var sessionID: UUID?
    /// The plan this entry was logged from; `nil` for a free (unplanned) log.
    var planID: UUID?

    init(id: UUID = UUID(),
         exerciseID: UUID,
         date: Date = .now,
         sets: [LoggedSet],
         note: String? = nil,
         sessionID: UUID? = nil,
         planID: UUID? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.date = date
        self.sets = sets
        self.note = note
        self.sessionID = sessionID
        self.planID = planID
    }

    /// Total repetitions across the rep-based sets. Timed (isometric) sets are
    /// excluded — their work is measured in `totalSeconds`, never mixed in here.
    var totalReps: Int { sets.totalReps }

    /// Total seconds held across the timed (isometric) sets; `0` when the entry
    /// holds none.
    var totalSeconds: Int { sets.totalSeconds }

    /// Whether every set in this entry is a timed hold, so its work reads in
    /// seconds rather than repetitions.
    var isTimed: Bool {
        !sets.isEmpty && sets.allSatisfy(\.isTimed)
    }

    /// The entry with every rep-type set of a seconds-measured exercise read
    /// as a hold of that many seconds (audit A-8): logs from before an
    /// exercise became a hold, or saved by an old prefill, stored the seconds
    /// in `reps`. Entries already in the exercise's unit come back unchanged.
    var inCatalogUnits: WorkoutLogEntry {
        guard sets.contains(where: { !$0.isTimed }),
              ExerciseCatalog.exercise(withID: exerciseID)?.measurement == .seconds
        else { return self }
        var copy = self
        copy.sets = sets.map { set in
            set.isTimed ? set : LoggedSet(reps: 1, weight: set.weight, durationSeconds: set.reps)
        }
        return copy
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
