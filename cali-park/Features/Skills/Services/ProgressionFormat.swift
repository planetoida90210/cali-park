import Foundation

// MARK: - ProgressionFormat
/// Formats progression criteria and logged progress for display, honoring each
/// criterion's measure. Rep targets read as "3 × 8", holds as "3 × 20 s", and
/// the "you own it" markers as "pierwsze czyste" / "pierwsze 5 s". Best-effort
/// copy pairs the target with the athlete's logged best ("3 × 8 — Twoje
/// najlepsze: 3 × 6"). On-screen the seconds unit stays the invariant "s";
/// spoken variants spell it out for VoiceOver.
enum ProgressionFormat {
    /// The unit symbol for a hold — invariant in Polish, like "kg".
    private static let secondsUnit = "s"

    /// The target for a rung: "3 × 8" for reps, "3 × 20 s" for holds, or the
    /// mastery markers "pierwsze czyste" / "pierwsze 5 s" for single-effort
    /// skills. A unilateral rung counts per side: "3 × 5 na rękę".
    static func criterion(_ criterion: AdvancementCriterion,
                          side: UnilateralSide? = nil) -> String {
        let target = switch criterion {
        case let .setsOfReps(sets, reps):
            sets == 1 && reps == 1 ? "pierwsze czyste" : "\(sets) × \(reps)"
        case let .setsOfHold(sets, seconds):
            sets == 1 ? "pierwsze \(seconds) \(secondsUnit)" : "\(sets) × \(seconds) \(secondsUnit)"
        }
        return withSide(target, side)
    }

    /// The target for a step, counted per side when its exercise is
    /// unilateral.
    static func criterion(for step: ProgressionStep) -> String {
        criterion(step.criterion, side: step.unilateralSide)
    }

    /// The athlete's best logged effort toward a rung, or `nil` when no session
    /// has counted yet (or when a single-rep marker leaves nothing partial to
    /// show).
    static func best(_ progress: RungProgress) -> String? {
        guard progress.bestValue > 0 else { return nil }
        switch progress.criterion {
        case .setsOfReps:
            return progress.targetSets == 1 ? nil : "\(progress.targetSets) × \(progress.bestValue)"
        case .setsOfHold:
            return progress.targetSets == 1
                ? "\(progress.bestValue) \(secondsUnit)"
                : "\(progress.targetSets) × \(progress.bestValue) \(secondsUnit)"
        }
    }

    /// The target paired with the logged best: "3 × 8 — Twoje najlepsze: 3 × 6",
    /// or just the target when nothing counts yet.
    static func progressLine(_ progress: RungProgress, side: UnilateralSide? = nil) -> String {
        let target = criterion(progress.criterion, side: side)
        guard let best = best(progress) else { return target }
        return "\(target) — Twoje najlepsze: \(best)"
    }

    /// A one-line nudge toward the athlete's most actionable rung, resolving the
    /// catalog names for display: "Jeszcze 2 powtórzenia do 3 × 8 — następny
    /// szczebel: Pełne podciągnięcia". When the current rung is the skill itself
    /// (no rung follows), it names that rung instead of a next one. `nil` when
    /// the catalog can't resolve the hint.
    static func hintLine(_ hint: ProgressionHint) -> String? {
        guard let path = ProgressionCatalog.path(withID: hint.pathID),
              hint.currentRungIndex < path.steps.count else { return nil }

        let remaining = max(0, hint.progress.targetValue - hint.progress.bestValue)
        let remainingText: String
        switch hint.progress.criterion {
        case .setsOfReps: remainingText = PolishPlural.reps(remaining)
        case .setsOfHold: remainingText = "\(remaining) \(secondsUnit)"
        }
        let goal = criterion(hint.progress.criterion, side: path.steps[hint.currentRungIndex].unilateralSide)

        // The next rung to name skips parallel tracks: they are options, not
        // the next step (audit A-3).
        if let nextIndex = ProgressionEngine.nextMainLineRung(in: path, from: hint.currentRungIndex + 1),
           let next = ExerciseCatalog.exercise(withID: path.steps[nextIndex].exerciseID) {
            return "Jeszcze \(remainingText) do \(goal) — następny szczebel: \(next.name)"
        }

        // Top rung: name the skill being conquered rather than a next step.
        let current = ExerciseCatalog.exercise(withID: path.steps[hint.currentRungIndex].exerciseID)?.name ?? path.name
        return "Jeszcze \(remainingText) do \(goal) — \(current)"
    }

    /// Equipment for a rung by its Polish names, joined for display; any one
    /// piece is enough. "Masa ciała" when a rung needs none.
    static func equipment(_ equipment: [String]) -> String {
        equipment.isEmpty
            ? "Masa ciała"
            : equipment.map(EquipmentItem.displayName(for:)).joined(separator: " · ")
    }

    /// A spoken reading of a criterion for VoiceOver: "3 serie po 8 powtórzeń",
    /// "3 serie po 20 sekund", or the spelled-out mastery markers.
    static func spokenCriterion(_ criterion: AdvancementCriterion,
                                side: UnilateralSide? = nil) -> String {
        let spoken = switch criterion {
        case let .setsOfReps(sets, reps):
            sets == 1 && reps == 1
                ? "pierwsze czyste powtórzenie"
                : "\(PolishPlural.sets(sets)) po \(PolishPlural.reps(reps))"
        case let .setsOfHold(sets, seconds):
            sets == 1
                ? "pierwsze utrzymanie \(PolishPlural.seconds(seconds))"
                : "\(PolishPlural.sets(sets)) po \(PolishPlural.seconds(seconds))"
        }
        return withSide(spoken, side)
    }

    /// The spoken target for a step, per side when its exercise is unilateral.
    static func spokenCriterion(for step: ProgressionStep) -> String {
        spokenCriterion(step.criterion, side: step.unilateralSide)
    }

    /// Appends the per-side suffix ("na rękę") when there is one.
    private static func withSide(_ text: String, _ side: UnilateralSide?) -> String {
        guard let side else { return text }
        return "\(text) \(side.label)"
    }
}
