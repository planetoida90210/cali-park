import Foundation
import Observation
import os

// MARK: - SkillPathsViewModel
/// Drives the Skills tab: turns the workout log and the athlete's placement into
/// per-path summaries, an overall level, earned badges, and the reward loop —
/// the queue of advances to celebrate and the XP a save just gained.
///
/// Loading is synchronous because the stores it reads are synchronous (an
/// in-memory or on-disk JSON file), matching `HomeDashboardViewModel`; there is
/// no async I/O to cancel. Reload on appear and after a training or calibration
/// sheet picks up changes made elsewhere.
@MainActor
@Observable
final class SkillPathsViewModel {
    // MARK: State
    /// One summary per catalog path, in catalog order.
    private(set) var summaries: [SkillPathSummary] = []
    /// The athlete's level, derived from the whole log history.
    private(set) var level: PlayerLevel = .forXP(0)
    /// Whether the athlete has declared a placement yet; drives the first-contact
    /// calibration prompt.
    private(set) var hasPlacement = false
    /// Paths whose conquered-rung count grew since the previous load. Empty on
    /// the first load, so an initial placement never counts as an advance.
    private(set) var recentlyAdvancedPaths: Set<ProgressionPathID> = []
    /// Badges earned from the whole log history; declarations never grant one.
    private(set) var badges: Set<Badge> = []
    /// The advance being celebrated right now, or `nil` when the queue is empty.
    private(set) var currentCelebration: CelebrationEvent?
    /// XP gained by the most recent save, to show as a toast; `nil` when there
    /// is nothing fresh to announce (or a celebration is carrying the moment).
    private(set) var xpToastAmount: Int?
    /// Set when the log or placement fails to load, for the Skills alert.
    var errorMessage: String?
    /// Whether the last load failed. The tab then keeps its previous state and
    /// must not offer calibration: an unreadable placement is not a missing one.
    private(set) var hasLoadError = false

    /// Advances waiting behind `currentCelebration`, shown one at a time.
    private var pendingCelebrations: [CelebrationEvent] = []
    /// Total XP at the previous load, to measure a save's gain; `nil` until the
    /// first load, so opening the tab never toasts historical XP.
    private var previousTotalXP: Int?

    /// The most recent logs, kept so any single rung can be scored on demand
    /// (the ladder detail shows a best for every rung, not just the current one).
    private var logs: [WorkoutLogEntry] = []

    private let logger = AppLog.logger(category: "SkillPaths")

    // MARK: Dependencies
    private let logStore: WorkoutLogStoring
    private let placementStore: PlacementStoring
    private let progressStore: SkillProgressStoring

    // MARK: Init
    init(logStore: WorkoutLogStoring,
         placementStore: PlacementStoring,
         progressStore: SkillProgressStoring) {
        self.logStore = logStore
        self.placementStore = placementStore
        self.progressStore = progressStore
        load()
    }

    // MARK: Intentions
    /// Recomputes every path's state, the level, and any fresh advances from the
    /// current logs and placement.
    func load() {
        let placement: SkillPlacement?
        do {
            logs = try logStore.load()
            placement = try placementStore.load()
            hasLoadError = false
        } catch {
            // Alert once per failure streak, not on every appear.
            if !hasLoadError { errorMessage = StoreLoadFailure.message }
            hasLoadError = true
            return
        }
        let states = ProgressionEngine.pathStates(logs: logs, placement: placement)

        let previous = summaries
        summaries = ProgressionCatalog.all.compactMap { path in
            states[path.id].map { SkillPathSummary(path: path, state: $0) }
        }
        level = ProgressionEngine.playerLevel(for: logs)
        hasPlacement = placement != nil
        badges = ProgressionEngine.earnedBadges(from: logs)
        recentlyAdvancedPaths = Self.advances(from: previous, to: summaries)

        enqueueFreshCelebrations(placement: placement)
        updateXPToast()
    }

    // MARK: Reward loop

    /// Compares logs against the "already celebrated" record and rebuilds the
    /// queue of advances still to show. An advance is added to the record only
    /// when its overlay is dismissed (`dismissCurrentCelebration`), so an
    /// evaluation that runs while the Skills tab is off screen, or an app quit
    /// mid-queue, never loses a celebration. The record is written here only
    /// when the evaluation changed it (a first-run baseline, or rungs conquered
    /// below the placement floor), not on every load.
    ///
    /// The placement is a floor only — it never adds a celebration.
    /// An unreadable record is skipped, not treated as "nothing celebrated":
    /// that would re-baseline silently and overwrite it.
    private func enqueueFreshCelebrations(placement: SkillPlacement?) {
        let celebrated: SkillProgress?
        do {
            celebrated = try progressStore.load()
        } catch {
            logger.error("Skipping rewards, progress unreadable: \(String(describing: error), privacy: .public)")
            return
        }
        let evaluation = RewardEvaluator.evaluate(
            logs: logs,
            placement: placement,
            celebrated: celebrated
        )
        if evaluation.updatedProgress != celebrated {
            do {
                try progressStore.save(evaluation.updatedProgress)
            } catch {
                // Safe to drop: the next load evaluates the same record again.
                logger.error("Cannot save reward progress: \(String(describing: error), privacy: .public)")
            }
        }
        replaceCelebrationQueue(with: evaluation.pendingEvents)
    }

    /// Makes `events` the queue. The overlay on screen stays put while it is
    /// still pending; an event another screen already showed drops out.
    private func replaceCelebrationQueue(with events: [CelebrationEvent]) {
        if let current = currentCelebration, events.contains(current) {
            pendingCelebrations = events.filter { $0 != current }
        } else {
            currentCelebration = events.first
            pendingCelebrations = Array(events.dropFirst())
        }
    }

    /// Adds a shown event to the persisted record, re-reading it first so a
    /// mark made by another Skills screen is kept. A failed write only means
    /// the event may play once more.
    private func markCelebrated(_ event: CelebrationEvent) {
        do {
            // No record means the baseline was never saved; marking now would
            // turn that into a near-empty record and replay history.
            guard let record = try progressStore.load() else { return }
            let marked = record.markingCelebrated(event)
            if marked != record { try progressStore.save(marked) }
        } catch {
            logger.error("Cannot mark celebration as shown: \(String(describing: error), privacy: .public)")
        }
    }

    /// Sets the XP toast to a save's gain, unless this is the first load (no
    /// baseline yet) or a celebration is already carrying the moment.
    private func updateXPToast() {
        let total = level.totalXP
        defer { previousTotalXP = total }
        guard let previous = previousTotalXP, total > previous else {
            xpToastAmount = nil
            return
        }
        xpToastAmount = currentCelebration == nil ? total - previous : nil
    }

    /// Whether to offer the calibration prompt: no placement declared yet, and
    /// not merely an unreadable one.
    var needsCalibration: Bool { !hasPlacement && !hasLoadError }

    /// Whether more advances wait behind the one on screen.
    var hasQueuedCelebrations: Bool { !pendingCelebrations.isEmpty }

    /// Records the overlay on screen as celebrated and moves to the next one.
    func dismissCurrentCelebration() {
        if let shown = currentCelebration { markCelebrated(shown) }
        currentCelebration = pendingCelebrations.isEmpty ? nil : pendingCelebrations.removeFirst()
    }

    /// Clears the XP toast once it has been shown.
    func clearXPToast() {
        xpToastAmount = nil
    }

    /// The summary for one path, or `nil` if the catalog has no such path.
    func summary(for id: ProgressionPathID) -> SkillPathSummary? {
        summaries.first { $0.id == id }
    }

    /// The athlete's best logged progress toward one rung, scored from the same
    /// logs the summaries use.
    func rungProgress(for step: ProgressionStep) -> RungProgress {
        ProgressionEngine.rungProgress(for: step, in: logs)
    }

    // MARK: Fresh advances
    /// The paths whose conquered-rung count rose between two snapshots. Returns
    /// nothing when there is no prior snapshot, so the first load celebrates
    /// nothing (a declaration is not an advance).
    static func advances(from old: [SkillPathSummary],
                         to new: [SkillPathSummary]) -> Set<ProgressionPathID> {
        guard !old.isEmpty else { return [] }
        let conqueredBefore = Dictionary(
            uniqueKeysWithValues: old.map { ($0.id, $0.state.conqueredRungCount) }
        )
        return Set(
            new.filter { summary in
                guard let before = conqueredBefore[summary.id] else { return false }
                return summary.state.conqueredRungCount > before
            }
            .map(\.id)
        )
    }
}
