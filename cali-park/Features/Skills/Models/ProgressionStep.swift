import Foundation

// MARK: - ProgressionStep
/// One rung on a progression ladder: an exercise plus the target that counts
/// as conquering it.
///
/// A step references a catalog exercise by `exerciseID` (main movement or
/// variant) rather than embedding it, so there is a single source of truth and
/// logs keyed by exercise ID work without special cases. `isParallelTrack`
/// marks optional side routes — the resistance-band pull-up, for instance —
/// that help but are never required to advance.
nonisolated struct ProgressionStep: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// The catalog exercise trained on this rung; also the step's identity,
    /// since an exercise appears at most once per path.
    let exerciseID: UUID
    /// What counts as conquering this rung.
    var criterion: AdvancementCriterion
    /// Where the criterion comes from (RR, OG2 table, our convention…).
    var criterionSource: CriterionSource
    /// How a rep or hold must look to count, when the criterion alone can't
    /// say it, e.g. "zjazd 5–10 s" on negatives. `nil` when nothing to add.
    var criterionNote: String?
    /// A non-binding tip shown on the rung, e.g. what RR builds before it.
    /// Never a condition: the ladder is a map, not a gate.
    var tip: String?
    /// Equipment this rung needs, matching `Park.equipments` keys (e.g.
    /// "Pull-up bar", "Resistance bands"). Any one of the listed pieces is
    /// enough: `["Pull-up bar", "Parallel bars"]` means a bar *or* parallel
    /// bars. Empty means bodyweight only.
    var equipment: [String]
    /// Whether this rung is an optional parallel route rather than part of the
    /// main line. The engine never makes a parallel rung the current one (see
    /// `ProgressionEngine.pathState`), but logging it still counts.
    var isParallelTrack: Bool

    var id: UUID { exerciseID }

    init(exerciseID: UUID,
         criterion: AdvancementCriterion,
         source criterionSource: CriterionSource,
         note criterionNote: String? = nil,
         tip: String? = nil,
         equipment: [String] = [],
         isParallelTrack: Bool = false) {
        self.exerciseID = exerciseID
        self.criterion = criterion
        self.criterionSource = criterionSource
        self.criterionNote = criterionNote
        self.tip = tip
        self.equipment = equipment
        self.isParallelTrack = isParallelTrack
    }

    /// How a unilateral rung is counted ("na rękę", "na nogę", "na stronę"),
    /// from the rung's exercise; `nil` for a two-sided movement.
    var unilateralSide: UnilateralSide? {
        ExerciseCatalog.exercise(withID: exerciseID)?.unilateralSide
    }
}
