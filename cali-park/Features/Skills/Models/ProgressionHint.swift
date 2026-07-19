import Foundation

// MARK: - ProgressionHint
/// The single most actionable rung to nudge the athlete toward: the current
/// rung they have partial-but-not-finished progress on, closest to its
/// criterion.
///
/// It is derived state (never persisted), produced by
/// `ProgressionEngine.mostActionableHint(logs:placement:)` and turned into a
/// display line by `ProgressionFormat.hintLine(_:)`. The Home hero shows it as a
/// secondary line on rest days and free-training days.
struct ProgressionHint: Equatable, Sendable {
    /// The path this nudge is about.
    let pathID: ProgressionPathID
    /// The rung the athlete trains now — the one with partial progress.
    let currentRungIndex: Int
    /// Progress toward conquering the current rung.
    let progress: RungProgress
}
