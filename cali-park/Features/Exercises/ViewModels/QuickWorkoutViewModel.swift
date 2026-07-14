import Foundation
import Observation

// MARK: - QuickWorkoutViewModel
/// Drives one "Szybki trening" session: the user adds any number of exercises
/// (each with its own sets) and saves the whole thing at the end. Exercises are
/// accumulated in memory and persisted together on `finish()` so a session is
/// all-or-nothing and groups under one `sessionID` in the history.
@MainActor
@Observable
final class QuickWorkoutViewModel {
    // MARK: DraftItem
    /// One exercise queued for the session, before it is persisted.
    struct DraftItem: Identifiable, Equatable {
        let id = UUID()
        let exercise: Exercise
        let sets: [LoggedSet]

        var totalReps: Int { sets.reduce(0) { $0 + $1.reps } }
    }

    // MARK: State
    private(set) var items: [DraftItem] = []
    var errorMessage: String?
    /// Set after a successful save so the session screen can dismiss itself.
    private(set) var didFinish = false

    // MARK: Dependencies
    private let store: WorkoutLogStoring
    /// Shared identifier stamped on every entry saved from this session.
    private let sessionID = UUID()

    // MARK: Init
    init(store: WorkoutLogStoring) {
        self.store = store
    }

    // MARK: Derived state
    var isEmpty: Bool { items.isEmpty }
    var canFinish: Bool { !items.isEmpty }
    var exerciseCount: Int { items.count }
    var totalSets: Int { items.reduce(0) { $0 + $1.sets.count } }

    // MARK: Intentions
    /// Queues an exercise with the sets logged on the SetPad. Empty logs are
    /// ignored so the session never holds a set-less exercise.
    func addExercise(_ exercise: Exercise, sets: [LoggedSet]) {
        guard !sets.isEmpty else { return }
        items.append(DraftItem(exercise: exercise, sets: sets))
    }

    func remove(_ item: DraftItem) {
        items.removeAll { $0.id == item.id }
    }

    /// Persists every queued exercise as one session (shared `sessionID` and a
    /// single timestamp). No-op when the session is empty.
    func finish() {
        guard canFinish else { return }

        let date = Date.now
        let entries = items.map { item in
            WorkoutLogEntry(
                exerciseID: item.exercise.id,
                date: date,
                sets: item.sets,
                sessionID: sessionID
            )
        }

        do {
            try store.append(contentsOf: entries)
            didFinish = true
        } catch {
            errorMessage = "Nie udało się zapisać treningu. Spróbuj ponownie."
        }
    }
}
