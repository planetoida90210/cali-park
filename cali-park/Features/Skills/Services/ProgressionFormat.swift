import Foundation

// MARK: - ProgressionFormat
/// Progression copy that resolves catalog names: the hero's "next rung" nudge
/// and a rung's equipment. Sets, reps, seconds and criteria are formatted by
/// `MeasureFormat`.
nonisolated enum ProgressionFormat {
    /// A one-line nudge toward the athlete's most actionable rung, resolving the
    /// catalog names for display: "Jeszcze 2 powtórzenia do 3 × 8 — następny
    /// szczebel: Pełne podciągnięcia". When the current rung is the skill itself
    /// (no rung follows), it names that rung instead of a next one. `nil` when
    /// the catalog can't resolve the hint.
    static func hintLine(_ hint: ProgressionHint) -> String? {
        guard let path = ProgressionCatalog.path(withID: hint.pathID),
            hint.currentRungIndex < path.steps.count
        else { return nil }

        let remaining = max(0, hint.progress.targetValue - hint.progress.bestValue)
        let remainingText = MeasureFormat.amount(remaining, hint.progress.criterion.measurement)
        let goal = MeasureFormat.criterionGoal(hint.progress.criterion, side: path.steps[hint.currentRungIndex].unilateralSide)

        // The next rung to name skips parallel tracks: they are options, not
        // the next step (audit A-3).
        if let nextIndex = ProgressionEngine.nextMainLineRung(in: path, from: hint.currentRungIndex + 1),
            let next = ExerciseCatalog.exercise(withID: path.steps[nextIndex].exerciseID)
        {
            return String(localized: "Jeszcze \(remainingText) do \(goal) — następny szczebel: \(next.name)")
        }

        // Top rung: name the skill being conquered rather than a next step.
        let current = ExerciseCatalog.exercise(withID: path.steps[hint.currentRungIndex].exerciseID)?.name ?? path.name
        return String(localized: "Jeszcze \(remainingText) do \(goal) — \(current)")
    }

    /// Equipment for a rung by its Polish names, joined for display; any one
    /// piece is enough. "Masa ciała" when a rung needs none.
    static func equipment(_ equipment: [String]) -> String {
        equipment.isEmpty
            ? String(localized: "Masa ciała")
            : equipment.map(ExerciseEquipment.displayName(for:)).joined(separator: " · ")
    }
}
