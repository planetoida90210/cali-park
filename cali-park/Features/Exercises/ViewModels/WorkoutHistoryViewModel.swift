import Foundation
import Observation

// MARK: - WorkoutHistorySection
/// One entry group in the history: either a quick-workout session (several
/// exercises sharing a `sessionID`) or a single standalone log.
struct WorkoutHistorySection: Identifiable {
    let id: String
    let date: Date
    let entries: [WorkoutLogEntry]

    /// A session card when it holds more than one exercise.
    var isSession: Bool { entries.count > 1 }
    var totalReps: Int { entries.reduce(0) { $0 + $1.totalReps } }
}

// MARK: - WorkoutHistoryViewModel
/// Drives the "Ostatnie treningi" list: loads log entries (newest first),
/// groups quick-workout sessions together, deletes them on swipe and surfaces
/// failures for an alert.
@MainActor
@Observable
final class WorkoutHistoryViewModel {
    // MARK: State
    private(set) var entries: [WorkoutLogEntry] = []
    var errorMessage: String?

    // MARK: Dependencies
    private let store: WorkoutLogStoring

    // MARK: Init
    init(store: WorkoutLogStoring) {
        self.store = store
        reload()
    }

    // MARK: Intentions
    /// Re-reads the store; call when the view appears so entries saved from
    /// the SetPad show up without extra wiring.
    func reload() {
        entries = store.load().sorted { $0.date > $1.date }
    }

    func delete(_ entry: WorkoutLogEntry) {
        do {
            try store.delete(id: entry.id)
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = "Nie udało się usunąć wpisu. Spróbuj ponownie."
        }
    }

    /// Resolves the catalog exercise a log entry points to.
    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
    }

    /// Entries grouped for display: exercises sharing a `sessionID` collapse
    /// into one session, standalone logs stay on their own, all newest first.
    var sections: [WorkoutHistorySection] {
        var grouped: [UUID: [WorkoutLogEntry]] = [:]
        var sessionOrder: [UUID] = []
        var singles: [WorkoutLogEntry] = []

        for entry in entries {
            if let sessionID = entry.sessionID {
                if grouped[sessionID] == nil { sessionOrder.append(sessionID) }
                grouped[sessionID, default: []].append(entry)
            } else {
                singles.append(entry)
            }
        }

        var result: [WorkoutHistorySection] = []
        for sessionID in sessionOrder {
            let sessionEntries = grouped[sessionID] ?? []
            result.append(
                WorkoutHistorySection(
                    id: sessionID.uuidString,
                    date: sessionEntries.map(\.date).max() ?? .distantPast,
                    entries: sessionEntries
                )
            )
        }
        for entry in singles {
            result.append(
                WorkoutHistorySection(id: entry.id.uuidString, date: entry.date, entries: [entry])
            )
        }

        return result.sorted { $0.date > $1.date }
    }
}
