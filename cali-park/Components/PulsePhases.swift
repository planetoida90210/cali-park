import Foundation

// MARK: - PulsePhases
/// Phases for a `phaseAnimator(_:trigger:)` pulse. A triggered phase animator
/// runs through every phase once and settles back on the first, so
/// alternating rest and grown phases make a fixed number of beats instead
/// of an endless loop.
nonisolated enum PulsePhases {
    /// `count` beats: `[false, true, false, true, …]` with `count` `true`s,
    /// starting at rest. No beats for a count below 1.
    static func beats(_ count: Int) -> [Bool] {
        guard count > 0 else { return [false] }
        return (0..<count).flatMap { _ in [false, true] }
    }
}
