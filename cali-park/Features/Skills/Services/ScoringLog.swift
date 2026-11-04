import Foundation

// MARK: - ScoringLog
/// The workout log prepared once for scoring, so every rung, XP and badge
/// question reads the same view of it instead of re-scanning the raw entries.
///
/// Two rules are applied here, and only here:
///
/// - **One workout, one session (audit A-5).** Entries that share a
///   `sessionID` and an exercise are merged into one scoring session. An
///   exercise added twice to one quick workout (supersets: pull-ups, dips,
///   pull-ups, …) therefore counts toward "3 × 8 in one session". A standalone
///   SetPad save (no `sessionID`) stays its own session, so volume split
///   across separate saves still never adds up.
/// - **Holds are read in seconds (audit A-8).** A rep-type set logged for an
///   exercise measured in seconds (a plank saved before holds existed, or a
///   plan prefill from before hold targets) is read as that many seconds, the
///   same way `LoggedSet.padValue(for:)` reads it back into the SetPad. The
///   stored log is never rewritten.
nonisolated struct ScoringLog: Sendable {
    /// One exercise's sets in one workout.
    struct Session: Sendable, Equatable {
        /// When the workout was logged (the earliest of its merged entries).
        let date: Date
        let sets: [LoggedSet]
    }

    /// Every entry with its sets normalized to the exercise's measure, in
    /// saved order. Volume XP and the rep badge read these.
    let entries: [WorkoutLogEntry]
    private let sessionsByExercise: [UUID: [Session]]

    init(_ logs: [WorkoutLogEntry]) {
        let normalized = logs.map(Self.normalized)
        entries = normalized

        struct Key: Hashable {
            let session: UUID
            let exerciseID: UUID
        }
        var order: [Key] = []
        var merged: [Key: (date: Date, sets: [LoggedSet])] = [:]
        for entry in normalized {
            let key = Key(session: entry.sessionID ?? entry.id, exerciseID: entry.exerciseID)
            if let existing = merged[key] {
                merged[key] = (min(existing.date, entry.date), existing.sets + entry.sets)
            } else {
                order.append(key)
                merged[key] = (entry.date, entry.sets)
            }
        }
        var byExercise: [UUID: [Session]] = [:]
        for key in order {
            guard let value = merged[key] else { continue }
            byExercise[key.exerciseID, default: []].append(Session(date: value.date, sets: value.sets))
        }
        sessionsByExercise = byExercise
    }

    /// The scoring sessions logged for one exercise, in saved order.
    func sessions(for exerciseID: UUID) -> [Session] {
        sessionsByExercise[exerciseID] ?? []
    }

    /// `entry` with every rep-type set of a seconds-measured exercise read as
    /// a hold of that many seconds (`WorkoutLogEntry.inCatalogUnits`). The
    /// journal already reads entries this way; scoring repeats it for logs
    /// passed in directly.
    static func normalized(_ entry: WorkoutLogEntry) -> WorkoutLogEntry {
        entry.inCatalogUnits
    }
}
