import Foundation
import Observation

// MARK: - SkillPathsViewModel
/// Drives the Skills tab: turns the workout log and the athlete's placement into
/// per-path summaries, an overall level, and the set of paths that advanced
/// since the last load (a hook the reward loop in SK6 builds on).
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

    /// The most recent logs, kept so any single rung can be scored on demand
    /// (the ladder detail shows a best for every rung, not just the current one).
    private var logs: [WorkoutLogEntry] = []

    // MARK: Dependencies
    private let logStore: WorkoutLogStoring
    private let placementStore: PlacementStoring

    // MARK: Init
    init(logStore: WorkoutLogStoring, placementStore: PlacementStoring) {
        self.logStore = logStore
        self.placementStore = placementStore
        load()
    }

    // MARK: Intentions
    /// Recomputes every path's state, the level, and any fresh advances from the
    /// current logs and placement.
    func load() {
        logs = logStore.load()
        let placement = placementStore.load()
        let states = ProgressionEngine.pathStates(logs: logs, placement: placement)

        let previous = summaries
        summaries = ProgressionCatalog.all.compactMap { path in
            states[path.id].map { SkillPathSummary(path: path, state: $0) }
        }
        level = ProgressionEngine.playerLevel(for: logs)
        hasPlacement = placement != nil
        recentlyAdvancedPaths = Self.advances(from: previous, to: summaries)
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
