import Foundation
import Observation
import os

// MARK: - TrainingJournal
/// The app's one training journal: the only write path for workout log
/// entries, and the one place that reacts to a change in them.
///
/// `AppEnvironment` creates a single instance and hands it to every view model
/// that reads or writes logs, so a save on one screen (SetPad, quick workout,
/// Home) is seen by every other one without reload calls. Each successful
/// write bumps `revision` and runs the change handlers: `ProgressService`
/// rescoring (and through it the reward loop) and the reminder re-sync.
///
/// A store that throws on load never reads as an empty journal: `loadFailure`
/// is set, `entries` keeps what it held before (nothing, on the first load),
/// and every screen shows `StoreLoadFailure.message` instead of "no workouts".
@MainActor
@Observable
final class TrainingJournal {
    /// Alert copy when a workout could not be saved.
    static let saveFailureMessage = "Nie udało się zapisać treningu."
    /// Alert copy when a workout could not be deleted.
    static let deleteFailureMessage = "Nie udało się usunąć treningu."

    // MARK: State
    /// Every entry, in saved order.
    private(set) var entries: [WorkoutLogEntry] = []
    /// The same entries, newest first, for lists and "latest" questions.
    private(set) var newestFirst: [WorkoutLogEntry] = []
    /// Grows by one on every change to `entries`. Derived state (progress,
    /// rewards) is computed once per revision.
    private(set) var revision = 0
    /// Why the last load failed; `nil` when the journal was read.
    private(set) var loadFailure: StoreLoadFailure?

    // MARK: Dependencies
    private let store: WorkoutLogStoring
    @ObservationIgnored private var changeHandlers: [@MainActor () -> Void] = []
    private let logger = AppLog.logger(category: "TrainingJournal")

    // MARK: Init
    init(store: WorkoutLogStoring) {
        self.store = store
        reload()
    }

    var hasLoadFailure: Bool { loadFailure != nil }

    // MARK: Reading
    /// Re-reads the store. Every write goes through the journal, so this is
    /// only needed to retry after a failed load.
    func reload() {
        do {
            let loaded = try store.load()
            loadFailure = nil
            replaceEntries(with: loaded)
        } catch {
            logger.error("Workout log unreadable: \(String(describing: error), privacy: .public)")
            loadFailure = StoreLoadFailure(error)
        }
    }

    /// Retries the load when the last one failed; otherwise does nothing.
    func reloadIfFailed() {
        if loadFailure != nil { reload() }
    }

    // MARK: Writing
    /// Saves one entry, e.g. a SetPad log of a single exercise.
    func log(_ entry: WorkoutLogEntry) throws {
        try store.append(entry)
        didWrite { $0 + [entry] }
    }

    /// Saves a whole workout in one write, so it is all-or-nothing.
    func logSession(_ sessionEntries: [WorkoutLogEntry]) throws {
        guard !sessionEntries.isEmpty else { return }
        try store.append(contentsOf: sessionEntries)
        didWrite { $0 + sessionEntries }
    }

    /// Deletes every entry in `ids` in one write (a whole workout, or the
    /// rows swiped away in the history).
    func delete(ids: Set<UUID>) throws {
        guard !ids.isEmpty else { return }
        try store.delete(ids: ids)
        didWrite { $0.filter { !ids.contains($0.id) } }
    }

    // MARK: Observing
    /// Runs `handler` after every change to the entries. Handlers run in the
    /// order they were added, on the main actor.
    func onChange(_ handler: @escaping @MainActor () -> Void) {
        changeHandlers.append(handler)
    }

    // MARK: Helpers
    /// Applies a successful write in memory. When the journal was never read,
    /// the in-memory entries are not the saved ones, so it re-reads instead.
    private func didWrite(_ change: ([WorkoutLogEntry]) -> [WorkoutLogEntry]) {
        if loadFailure == nil {
            replaceEntries(with: change(entries))
        } else {
            reload()
        }
    }

    private func replaceEntries(with newEntries: [WorkoutLogEntry]) {
        guard newEntries != entries || revision == 0 else { return }
        entries = newEntries
        newestFirst = newEntries.sorted { $0.date > $1.date }
        revision += 1
        for handler in changeHandlers { handler() }
    }
}
