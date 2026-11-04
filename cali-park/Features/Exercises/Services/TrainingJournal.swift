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
///
/// Writes are `async`: the file store rewrites the whole journal off the main
/// actor (C-8, D-7). They run one at a time, in the order they were called, and
/// each one changes `entries` only after the store saved it, so the screens
/// never show a workout that is not on disk. A failed write throws to its
/// caller and leaves `entries` as they were. A write that started finishes even
/// when the caller's task is cancelled.
@MainActor
@Observable
final class TrainingJournal {
    /// Alert copy when a workout could not be saved.
    static let saveFailureMessage = String(localized: "Nie udało się zapisać treningu.")
    /// Alert copy when a workout could not be deleted.
    static let deleteFailureMessage = String(localized: "Nie udało się usunąć treningu.")

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
    /// The last write issued; the next one starts after it finishes.
    @ObservationIgnored private var lastWrite: Task<Void, any Error>?
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
    func log(_ entry: WorkoutLogEntry) async throws {
        try await enqueueWrite({ try await $0.append(entry) }, change: .appended([entry]))
    }

    /// Saves a whole workout in one write, so it is all-or-nothing.
    func logSession(_ sessionEntries: [WorkoutLogEntry]) async throws {
        guard !sessionEntries.isEmpty else { return }
        try await enqueueWrite({ try await $0.append(contentsOf: sessionEntries) },
                               change: .appended(sessionEntries))
    }

    /// Deletes every entry in `ids` in one write (a whole workout, or the
    /// rows swiped away in the history).
    func delete(ids: Set<UUID>) async throws {
        guard !ids.isEmpty else { return }
        try await enqueueWrite({ try await $0.delete(ids: ids) }, change: .removed(ids))
    }

    /// Replaces every entry in one write (importing a backup). Throws, and
    /// leaves the journal as it was, when the store refuses the write.
    ///
    /// `afterWrite` runs right after a successful write is applied and the
    /// change handlers ran, before any other main-actor work, so a caller can
    /// settle other services before a screen renders the change (the backup
    /// rebaselines rewards there).
    func replaceAll(_ newEntries: [WorkoutLogEntry],
                    afterWrite: @escaping @MainActor () -> Void = {}) async throws {
        try await enqueueWrite({ try await $0.replaceAll(with: newEntries) },
                               change: .replaced(newEntries),
                               afterWrite: afterWrite)
    }

    /// Waits until every write issued so far has finished, failed or not.
    func waitForPendingWrites() async {
        _ = await lastWrite?.result
    }

    // MARK: Observing
    /// Runs `handler` after every change to the entries. Handlers run in the
    /// order they were added, on the main actor.
    func onChange(_ handler: @escaping @MainActor () -> Void) {
        changeHandlers.append(handler)
    }

    // MARK: Helpers
    /// Runs `write` once every earlier write finished, then applies `change`
    /// in memory. The work runs in its own task, so cancelling the caller
    /// never stops a write halfway; the caller still gets its error.
    private func enqueueWrite(_ write: @escaping @MainActor (WorkoutLogStoring) async throws -> Void,
                              change: Change,
                              afterWrite: @escaping @MainActor () -> Void = {}) async throws {
        let previous = lastWrite
        let task = Task {
            _ = await previous?.result
            try await write(store)
            didWrite(change)
            afterWrite()
        }
        lastWrite = task
        try await task.value
    }

    /// What a successful write did, to apply it in memory.
    private enum Change {
        case appended([WorkoutLogEntry])
        case removed(Set<UUID>)
        case replaced([WorkoutLogEntry])
    }

    /// Applies a successful write in memory. When the journal was never read,
    /// the in-memory entries are not the saved ones, so it re-reads instead.
    /// Appends and deletes update `newestFirst` in place rather than sorting
    /// the whole journal again; the result is the same as a full stable sort.
    private func didWrite(_ change: Change) {
        guard loadFailure == nil else {
            reload()
            return
        }
        switch change {
        case .appended(let added):
            guard !added.isEmpty else { return }
            var newest = newestFirst
            for entry in added {
                // After every entry at least as new, as a stable sort puts it.
                newest.insert(entry, at: newest.partitioningIndex { $0.date < entry.date })
            }
            apply(entries + added, newestFirst: newest)
        case .removed(let ids):
            let kept = entries.filter { !ids.contains($0.id) }
            guard kept.count != entries.count else { return }
            apply(kept, newestFirst: newestFirst.filter { !ids.contains($0.id) })
        case .replaced(let newEntries):
            replaceEntries(with: newEntries)
        }
    }

    private func replaceEntries(with newEntries: [WorkoutLogEntry]) {
        guard newEntries != entries || revision == 0 else { return }
        apply(newEntries, newestFirst: newEntries.sorted { $0.date > $1.date })
    }

    private func apply(_ newEntries: [WorkoutLogEntry], newestFirst newest: [WorkoutLogEntry]) {
        entries = newEntries
        newestFirst = newest
        revision += 1
        for handler in changeHandlers { handler() }
    }
}

// MARK: - Binary search
private extension Array {
    /// The first index whose element satisfies `belongsInSecondPart`, for an
    /// array already partitioned by it (every `false` before every `true`).
    nonisolated func partitioningIndex(where belongsInSecondPart: (Element) -> Bool) -> Int {
        var low = startIndex
        var high = endIndex
        while low < high {
            let middle = low + (high - low) / 2
            if belongsInSecondPart(self[middle]) {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return low
    }
}
