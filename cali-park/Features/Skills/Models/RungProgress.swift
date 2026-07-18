import Foundation

// MARK: - RungProgress
/// How close the athlete's logs come to conquering one rung's criterion.
///
/// `bestValue` is the athlete's best effort *in a single session*: the value
/// (reps or seconds) of the weakest set among their best `criterion.sets` sets.
/// It is `0` until a session logs at least that many qualifying sets, which is
/// why "3 × 8 in one session" counts while the same volume split across sessions
/// does not. This value only ever rises — a met rung stays met, so a bad week
/// never demotes a ladder.
struct RungProgress: Equatable, Sendable {
    /// The target this rung is scored against.
    let criterion: AdvancementCriterion
    /// The athlete's best single-session value toward the criterion, in reps or
    /// seconds; `0` when no session has enough qualifying sets yet.
    let bestValue: Int

    /// The number of sets the criterion asks for (e.g. 3 in "3 × 8").
    var targetSets: Int { criterion.sets }

    /// The value each set must reach (reps or seconds).
    var targetValue: Int { criterion.targetValue }

    /// Whether the logs satisfy the criterion.
    var isMet: Bool { bestValue >= criterion.targetValue }

    /// Fraction of the target value reached, clamped to `0...1`. Suitable for a
    /// progress ring; the exact "3 × 8 — your best: 3 × 6" copy is built in SK5
    /// from `targetSets`, `targetValue`, and `bestValue`.
    var fractionComplete: Double {
        guard criterion.targetValue > 0 else { return isMet ? 1 : 0 }
        return min(1, Double(bestValue) / Double(criterion.targetValue))
    }
}
