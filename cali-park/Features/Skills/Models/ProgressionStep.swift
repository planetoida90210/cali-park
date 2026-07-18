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
struct ProgressionStep: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// The catalog exercise trained on this rung; also the step's identity,
    /// since an exercise appears at most once per path.
    let exerciseID: UUID
    /// What counts as conquering this rung.
    var criterion: AdvancementCriterion
    /// Equipment this rung needs, matching `Park.equipments` strings
    /// (e.g. "Pull-up bar", "Resistance bands"). Empty means bodyweight only.
    var equipment: [String]
    /// Whether this rung is an optional parallel route rather than part of the
    /// main line — true only for equipment-assisted alternatives like bands.
    var isParallelTrack: Bool

    var id: UUID { exerciseID }

    init(exerciseID: UUID,
         criterion: AdvancementCriterion,
         equipment: [String] = [],
         isParallelTrack: Bool = false) {
        self.exerciseID = exerciseID
        self.criterion = criterion
        self.equipment = equipment
        self.isParallelTrack = isParallelTrack
    }
}
