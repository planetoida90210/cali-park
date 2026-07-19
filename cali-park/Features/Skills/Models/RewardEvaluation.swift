import Foundation

// MARK: - RewardEvaluation
/// The outcome of comparing what the athlete has earned from logs against what
/// has already been celebrated: the events still to show, and the updated
/// "already celebrated" record to persist.
///
/// Produced by `RewardEvaluator.evaluate(logs:celebrated:)`. Persisting
/// `updatedProgress` after presenting `pendingEvents` is what keeps the reward
/// loop idempotent — each advance is celebrated exactly once.
struct RewardEvaluation: Equatable, Sendable {
    /// Advances to celebrate now, in display order (rungs first, then levels).
    let pendingEvents: [CelebrationEvent]
    /// The record to save so these advances are not celebrated again.
    let updatedProgress: SkillProgress
}
