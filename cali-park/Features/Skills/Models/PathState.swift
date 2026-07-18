import Foundation

// MARK: - PathState
/// The computed state of one progression path for a given athlete: which rungs
/// are conquered, which one they train now, and how close they are to the next.
///
/// Paths are scored independently — one path's state never depends on another,
/// so 70 pull-ups do not hand you a muscle-up. Produced by `ProgressionEngine`
/// from logs and (optionally) a `SkillPlacement`; it is derived state, never
/// persisted.
struct PathState: Identifiable, Equatable, Sendable {
    /// The path this state describes.
    let pathID: ProgressionPathID
    /// Total number of rungs on the path's ladder.
    let rungCount: Int
    /// Index of the rung the athlete trains now — the first unconquered rung,
    /// or the top rung once the whole ladder is conquered.
    let currentRungIndex: Int
    /// Number of conquered rungs; every rung below this index is conquered.
    let conqueredRungCount: Int
    /// Progress toward conquering the current rung.
    let currentProgress: RungProgress

    var id: ProgressionPathID { pathID }

    /// Whether every rung, including the skill itself, is conquered.
    var isComplete: Bool { conqueredRungCount >= rungCount }

    /// Whether the rung at `index` counts as conquered (from logs or a
    /// declaration).
    func isConquered(rungAt index: Int) -> Bool {
        index < conqueredRungCount
    }

    /// Whether the rung at `index` is the one currently being trained.
    func isCurrent(rungAt index: Int) -> Bool {
        index == currentRungIndex
    }
}
