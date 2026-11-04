import Foundation

// MARK: - RewardEvaluation
/// The outcome of comparing what the athlete has earned from logs against what
/// has already been celebrated: the events still to show, and the updated
/// "already celebrated" record to persist.
///
/// Produced by `RewardEvaluator.evaluate(logs:placement:celebrated:)`.
/// `updatedProgress` excludes `pendingEvents`: the caller saves it right away
/// (it only changes when there is a baseline or a silently recorded rung to
/// keep) and adds each pending event to the record once it has been shown.
/// That keeps the reward loop idempotent without losing an advance whose
/// overlay never appeared.
nonisolated struct RewardEvaluation: Equatable, Sendable {
    /// Advances to celebrate now, in display order (rungs first, then levels).
    let pendingEvents: [CelebrationEvent]
    /// The record to save now, without the pending events.
    let updatedProgress: SkillProgress
}
