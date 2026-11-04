import Foundation
import Observation
import os

// MARK: - ProgressService
/// The app's one source of progress: the snapshot of path states, XP, level,
/// badges and conquered rungs, computed once per journal revision and
/// placement change and shared by Skills, Home, programs and the reward loop.
///
/// The computation itself is `ProgressionEngine.snapshot(...)`, a pure
/// function that takes 30–60 ms on a 10,000-entry journal. After a change it
/// runs off the main actor, and the result is published back here, so a save
/// never freezes the interface. Until it lands, `snapshot` keeps the previous
/// one: screens show the old progress for a moment, never an empty state.
/// The first snapshot is computed synchronously in `init`, because the journal
/// is read before the first screen, so launch never shows empty progress.
///
/// The latest change wins: every change cancels the computation in flight and
/// starts one from the current inputs, and only the newest one is published.
/// Change handlers (the reward loop) run once per published snapshot, so two
/// quick saves are evaluated together, never lost. Tests `await settle()`.
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

    /// The current progress: the newest snapshot published. Reading it is
    /// free and tracks every new one, so a save anywhere refreshes every
    /// screen that shows progress.
    private(set) var snapshot: ProgressSnapshot
    /// The inputs `snapshot` was computed for; grows with every published
    /// snapshot. Equal revisions mean equal snapshots.
    private(set) var revision: Int
    /// Whether a change is still being computed, so `snapshot` is about to
    /// be replaced. The reward overlay holds a met weekly goal meanwhile, so
    /// it never shows before the rungs the same save conquered.
    private(set) var isComputing = false

    /// How many snapshots were published; tests check it stays one per change.
    @ObservationIgnored private(set) var computationCount = 0
    /// The computation in flight, if any. Only the newest one publishes.
    @ObservationIgnored private var pending: Task<Void, Never>?
    /// Grows with every computation started, to tell the newest one apart.
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var changeHandlers: [@MainActor () -> Void] = []

    // MARK: Dependencies
    private let journal: TrainingJournal
    private let placementStore: SkillPlacementStoring
    private let calendar: Calendar
    private let clock: () -> Date

    // MARK: Init
    init(journal: TrainingJournal,
         placementStore: SkillPlacementStoring,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.journal = journal
        self.placementStore = placementStore
        self.calendar = calendar
        self.clock = clock
        var loadedPlacement: SkillPlacement?
        switch Self.readPlacement(from: placementStore) {
        case .success(let loaded):
            loadedPlacement = loaded
        case .failure(let failure):
            placementFailure = failure
        }
        placement = loadedPlacement
        // Synchronous once: the journal is already read, and the first screen
        // must not show empty progress.
        let input = Input(logs: journal.entries, placement: loadedPlacement, calendar: calendar,
                          today: clock(), revision: journal.revision)
        snapshot = input.snapshot()
        revision = input.revision
        computationCount = 1
        journal.onChange { [weak self] in self?.inputsChanged() }
    }

    // MARK: Output
    /// Why progress can't be trusted right now: the journal or the placement
    /// could not be read. Screens then keep what they showed and say so.
    var loadFailure: StoreLoadFailure? { journal.loadFailure ?? placementFailure }

    var hasLoadError: Bool { loadFailure != nil }

    // MARK: Intentions
    /// Re-reads the placement after it was saved (calibration, onboarding).
    func reloadPlacement() {
        switch Self.readPlacement(from: placementStore) {
        case .success(let loaded):
            let recovered = placementFailure != nil
            placementFailure = nil
            if loaded != placement {
                placement = loaded
                placementRevision += 1
                inputsChanged()
            } else if recovered {
                inputsChanged()
            }
        case .failure(let failure):
            placementFailure = failure
        }
    }

    /// Retries whatever failed to load last time.
    func reloadIfFailed() {
        journal.reloadIfFailed()
        if placementFailure != nil { reloadPlacement() }
    }

    /// Runs `handler` after every new snapshot is published, on the main
    /// actor. A burst of changes publishes once, for the newest inputs.
    func onChange(_ handler: @escaping @MainActor () -> Void) {
        changeHandlers.append(handler)
    }

    /// Waits until the snapshot reflects every change made so far.
    func settle() async {
        while let pending { await pending.value }
    }

    /// Publishes the snapshot for the current inputs right now, on the main
    /// actor, when a computation is still in flight. Only for the rare caller
    /// that must evaluate the new progress in the same main-actor turn as the
    /// change (importing a backup rebaselines the rewards silently).
    func settleSynchronously() {
        guard pending != nil else { return }
        let input = currentInput()
        cancelPending()
        publish(input.snapshot(), revision: input.revision)
    }

    // MARK: Helpers
    /// The inputs of a snapshot now. `revision` grows with every journal or
    /// placement change, as both counters only grow.
    private func currentInput() -> Input {
        Input(logs: journal.entries, placement: placement, calendar: calendar,
              today: clock(), revision: journal.revision + placementRevision)
    }

    /// Starts computing a snapshot for the current inputs off the main actor,
    /// replacing any computation in flight.
    private func inputsChanged() {
        cancelPending()
        let generation = generation
        let input = currentInput()
        isComputing = true
        pending = Task { [weak self] in
            let snapshot = await Self.compute(input)
            guard let self, generation == self.generation, let snapshot else { return }
            self.pending = nil
            self.publish(snapshot, revision: input.revision)
        }
    }

    private func cancelPending() {
        pending?.cancel()
        pending = nil
        generation += 1
    }

    private func publish(_ newSnapshot: ProgressSnapshot, revision newRevision: Int) {
        isComputing = false
        snapshot = newSnapshot
        revision = newRevision
        computationCount += 1
        for handler in changeHandlers { handler() }
    }

    /// `ProgressionEngine.snapshot` on the cooperative pool, or `nil` when a
    /// newer change cancelled it before it started.
    @concurrent
    private nonisolated static func compute(_ input: Input) async -> ProgressSnapshot? {
        guard !Task.isCancelled else { return nil }
        return input.snapshot()
    }

    private static func readPlacement(from store: SkillPlacementStoring) -> Result<SkillPlacement?, StoreLoadFailure> {
        do {
            return .success(try store.load())
        } catch {
            AppLog.logger(category: "ProgressService").error("Placement unreadable: \(String(describing: error), privacy: .public)")
            return .failure(StoreLoadFailure(error))
        }
    }

    /// Everything a snapshot is computed from, copied off the main actor.
    private nonisolated struct Input: Sendable {
        let logs: [WorkoutLogEntry]
        let placement: SkillPlacement?
        let calendar: Calendar
        let today: Date
        let revision: Int

        func snapshot() -> ProgressSnapshot {
            ProgressionEngine.snapshot(logs: logs, placement: placement, calendar: calendar, today: today)
        }
    }
}
