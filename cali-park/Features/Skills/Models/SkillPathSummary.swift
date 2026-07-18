import Foundation

// MARK: - SkillPathSummary
/// A progression path paired with its computed state, ready to present on a
/// card or a ladder.
///
/// It bundles the static ladder (`ProgressionCatalog`) with the athlete's
/// derived `PathState` (from `ProgressionEngine`) so views read one value
/// instead of resolving both. Like `PathState`, it is derived, never persisted.
struct SkillPathSummary: Identifiable, Equatable, Sendable {
    /// The static ladder definition.
    let path: ProgressionPath
    /// The athlete's computed progress along that ladder.
    let state: PathState

    var id: ProgressionPathID { path.id }

    /// The rung the athlete trains now.
    var currentStep: ProgressionStep {
        path.steps[state.currentRungIndex]
    }

    /// Progress toward conquering the current rung.
    var currentProgress: RungProgress {
        state.currentProgress
    }
}
