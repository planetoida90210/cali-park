import Foundation
import Observation
import os

// MARK: - ProgressService
/// The app's one source of progress: the snapshot of path states, XP, level,
/// badges and conquered rungs, computed once per journal revision and
/// placement change and shared by Skills, Home, programs and the reward loop.
///
/// The computation itself is `ProgressionEngine.snapshot(...)`, a pure
/// function; this service only decides when to run it. Reading `snapshot` in
/// a view body is cheap and tracks the journal, so a save anywhere refreshes
/// every screen that shows progress.
@MainActor
@Observable
final class ProgressService {
    // MARK: State
    /// The athlete's declaration, as last read.
    private(set) var placement: SkillPlacement?
    /// Why the last placement read failed; `nil` when it was read.
    private(set) var placementFailure: StoreLoadFailure?
    /// Grows on every placement reload that changed it.
    private var placementRevision = 0

    /// The last snapshot and the revisions it was computed for.
    @ObservationIgnored private var cache: (key: Key, snapshot: ProgressSnapshot)?
    /// How many snapshots were computed; tests check it stays one per change.
    @ObservationIgnored private(set) var computationCount = 0
    @ObservationIgnored private var changeHandlers: [@MainActor () -> Void] = []

    // MARK: Dependencies
    private let journal: TrainingJournal
    private let placementStore: PlacementStoring
    private let calendar: Calendar
    private let clock: () -> Date
    private let logger = AppLog.logger(category: "ProgressService")

    private struct Key: Equatable {
        let journal: Int
        let placement: Int
    }

    // MARK: Init
    init(journal: TrainingJournal,
         placementStore: PlacementStoring,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.journal = journal
        self.placementStore = placementStore
        self.calendar = calendar
        self.clock = clock
        readPlacement()
        journal.onChange { [weak self] in self?.notifyChange() }
    }

    // MARK: Output
    /// The current progress, recomputed only when the journal or the
    /// placement changed since the last read.
    var snapshot: ProgressSnapshot {
        let key = Key(journal: journal.revision, placement: placementRevision)
        if let cache, cache.key == key { return cache.snapshot }
        let snapshot = ProgressionEngine.snapshot(logs: journal.entries,
                                                  placement: placement,
                                                  calendar: calendar,
                                                  today: clock())
        cache = (key, snapshot)
        computationCount += 1
        return snapshot
    }

    /// Grows whenever the inputs of `snapshot` change.
    var revision: Int { journal.revision + placementRevision }

    /// Why progress can't be trusted right now: the journal or the placement
    /// could not be read. Screens then keep what they showed and say so.
    var loadFailure: StoreLoadFailure? { journal.loadFailure ?? placementFailure }

    var hasLoadError: Bool { loadFailure != nil }

    // MARK: Intentions
    /// Re-reads the placement after it was saved (calibration, onboarding).
    func reloadPlacement() {
        if readPlacement() { notifyChange() }
    }

    /// Retries whatever failed to load last time.
    func reloadIfFailed() {
        journal.reloadIfFailed()
        if placementFailure != nil { reloadPlacement() }
    }

    /// Runs `handler` after every change to the snapshot's inputs.
    func onChange(_ handler: @escaping @MainActor () -> Void) {
        changeHandlers.append(handler)
    }

    // MARK: Helpers
    /// Reads the placement; returns whether it changed or became readable.
    @discardableResult
    private func readPlacement() -> Bool {
        do {
            let loaded = try placementStore.load()
            let recovered = placementFailure != nil
            placementFailure = nil
            guard loaded != placement else { return recovered }
            placement = loaded
            placementRevision += 1
            return true
        } catch {
            logger.error("Placement unreadable: \(String(describing: error), privacy: .public)")
            placementFailure = StoreLoadFailure(error)
            return false
        }
    }

    private func notifyChange() {
        for handler in changeHandlers { handler() }
    }
}
