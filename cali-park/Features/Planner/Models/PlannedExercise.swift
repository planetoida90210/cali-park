import Foundation

// MARK: - PlannedExercise
/// One exercise inside a `WorkoutPlan`, referenced by its stable catalog
/// `exerciseID`. Targets are optional: a plan can just list the movements, or
/// prescribe sets/reps to prefill the SetPad when the session starts.
struct PlannedExercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var exerciseID: UUID
    var targetSets: Int?
    var targetReps: Int?

    init(id: UUID = UUID(),
         exerciseID: UUID,
         targetSets: Int? = nil,
         targetReps: Int? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
}
