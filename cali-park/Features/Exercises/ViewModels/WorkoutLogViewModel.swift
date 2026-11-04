import Foundation
import Observation

// MARK: - WorkoutLogViewModel
/// Drives one SetPad session for a single exercise: holds the `SetPadInput`
/// state, saves the finished entry to the `TrainingJournal` and surfaces
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
    /// Whether a save is being written, so a second tap waits for it.
    private(set) var isSaving = false

    /// Whether closing now would drop typed sets that are not saved yet.
    var hasUnsavedChanges: Bool { !didSave && input != SetPadInput() }

    // MARK: Dependencies
    private let journal: TrainingJournal

    // MARK: Init
    init(exercise: Exercise, journal: TrainingJournal) {
        self.exercise = exercise
        self.journal = journal
    }

    // MARK: Intentions
    /// Persists the current sets (committed + pending entry) as one log entry.
    /// No-op when there is nothing to save, or when this entry is already
    /// saved or being saved (a second tap while the sheet closes must not log
    /// it twice).
    func save() async {
        guard !didSave, !isSaving else { return }
        let sets = input.loggedSets(for: exercise.measurement)
        guard !sets.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }
        do {
            try await journal.log(WorkoutLogEntry(exerciseID: exercise.id, sets: sets))
            didSave = true
        } catch {
            errorMessage = TrainingJournal.saveFailureMessage
        }
    }
}
