import Foundation

// MARK: - WorkoutSession
/// One workout as the user thinks of it: every exercise saved together from a
/// "Szybki trening" (entries sharing a `sessionID`), or a single standalone log.
/// Derived from log entries on read and never persisted, so the on-disk
/// `WorkoutLogEntry` format stays unchanged. Shared by Home, the history list
/// and the workout detail screen.
struct WorkoutSession: Identifiable, Hashable {
    /// The shared `sessionID`, or the entry's own `id` for a standalone log.
    let id: UUID
    let date: Date
    /// The session's exercises in the order they were saved.
    let entries: [WorkoutLogEntry]

    init(id: UUID, date: Date, entries: [WorkoutLogEntry]) {
        self.id = id
        self.date = date
        self.entries = entries
    }

    /// Whether this groups several exercises (a multi-exercise quick workout).
    var isSession: Bool { entries.count > 1 }
    var totalReps: Int { entries.reduce(0) { $0 + $1.totalReps } }
    var totalSeconds: Int { entries.reduce(0) { $0 + $1.totalSeconds } }
    var totalSets: Int { entries.reduce(0) { $0 + $1.sets.count } }

    // MARK: Grouping
    /// Groups `entries` into workouts, newest first: entries sharing a
    /// `sessionID` collapse into one workout dated by its latest entry, while
    /// standalone logs stay on their own even when logged the same day.
    static func grouped(from entries: [WorkoutLogEntry]) -> [WorkoutSession] {
        var grouped: [UUID: [WorkoutLogEntry]] = [:]
        var sessionOrder: [UUID] = []
        var result: [WorkoutSession] = []

        for entry in entries {
            if let sessionID = entry.sessionID {
                if grouped[sessionID] == nil { sessionOrder.append(sessionID) }
                grouped[sessionID, default: []].append(entry)
            } else {
                result.append(WorkoutSession(id: entry.id, date: entry.date, entries: [entry]))
            }
        }

        for sessionID in sessionOrder {
            let sessionEntries = grouped[sessionID] ?? []
            result.append(
                WorkoutSession(
                    id: sessionID,
                    date: sessionEntries.map(\.date).max() ?? .distantPast,
                    entries: sessionEntries
                )
            )
        }

        return result.sorted { $0.date > $1.date }
    }

    /// The workout holding the newest entry, or `nil` for an empty journal.
    static func latest(in entries: [WorkoutLogEntry]) -> WorkoutSession? {
        grouped(from: entries).first
    }

    /// The workout with the given identifier, or `nil` once it has been deleted.
    static func session(withID id: UUID, in entries: [WorkoutLogEntry]) -> WorkoutSession? {
        grouped(from: entries).first { $0.id == id }
    }
}
