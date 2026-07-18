import Foundation
import Observation

// MARK: - WorkoutLogViewModel
/// Drives one SetPad session for a single exercise: holds the `SetPadInput`
/// state, persists the finished entry through `WorkoutLogStoring` and surfaces
/// save failures for an alert.
@MainActor
@Observable
final class WorkoutLogViewModel {
    // MARK: State
    let exercise: Exercise
    var input = SetPadInput()
    var errorMessage: String?
    /// Set after a successful save so the sheet can dismiss itself.
    private(set) var didSave = false

    // MARK: Dependencies
    private let store: WorkoutLogStoring

    // MARK: Init
    init(exercise: Exercise, store: WorkoutLogStoring) {
        self.exercise = exercise
        self.store = store
    }

    // MARK: Intentions
    /// Persists the current sets (committed + pending entry) as one log entry.
    /// No-op when there is nothing to save.
    func save() {
        let sets = input.setsForSaving
        guard !sets.isEmpty else { return }

        let entry = WorkoutLogEntry(
            exerciseID: exercise.id,
            sets: sets.map { LoggedSet(value: $0, measurement: exercise.measurement) }
        )

        do {
            try store.append(entry)
            didSave = true
        } catch {
            errorMessage = "Nie udało się zapisać treningu. Spróbuj ponownie."
        }
    }
}
