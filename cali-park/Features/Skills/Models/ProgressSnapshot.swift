import Foundation

// MARK: - ProgressSnapshot
/// Everything the app shows about progress, computed in one pass over the log
/// by `ProgressionEngine.snapshot(logs:placement:calendar:today:)`: where the
/// athlete stands on each path, their XP and level, badges, the rungs the logs
/// have conquered, and the most actionable nudge.
///
/// `ProgressService` computes one off the main actor per journal revision and
/// placement change, so Skills, Home and the reward loop all read the same
/// numbers.
nonisolated struct ProgressSnapshot: Sendable {
    /// The athlete's declaration, or `nil` when none was saved.
    let placement: SkillPlacement?
    /// Every path's state, with the placement as a floor.
    let pathStates: [ProgressionPathID: PathState]
    /// Every path's state from logs alone. XP, badges and rewards read these,
    /// so a declaration never grants anything.
    let logPathStates: [ProgressionPathID: PathState]
    /// Level and XP from the whole log history.
    let level: PlayerLevel
    /// Badges the logs earn.
    let badges: Set<Badge>
    /// Every rung the logs have conquered, on every path.
    let conqueredRungs: Set<RungReference>
    /// The most recently conquered rung, from logs only.
    let lastAdvancement: RungReference?
    /// The current rung closest to done, respecting the placement floor.
    let hint: ProgressionHint?
    /// The scored log, kept so any rung can be scored on demand.
    let scoring: ScoringLog

    /// The athlete's best logged progress toward one rung.
    func rungProgress(for step: ProgressionStep) -> RungProgress {
        ProgressionEngine.rungProgress(for: step, in: scoring)
    }

    /// One summary per catalog path, in catalog order.
    var summaries: [SkillPathSummary] {
        ProgressionCatalog.all.compactMap { path in
            pathStates[path.id].map { SkillPathSummary(path: path, state: $0) }
        }
    }
}
