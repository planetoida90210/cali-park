import Foundation
import Observation

// MARK: - WorkoutHistoryViewModel
/// Drives the "Ostatnie treningi" list: loads log entries (newest first),
/// deletes them on swipe and surfaces failures for an alert.
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
}
