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
    /// One exercise queued for the session. Sets are empty while the item is
    /// still pending (seeded from a plan, awaiting confirmation on the SetPad).
    struct DraftItem: Identifiable, Equatable {
        let id = UUID()
        let exercise: Exercise
        var sets: [LoggedSet]

        /// A seeded plan exercise the user has not logged sets for yet.
        var isPending: Bool { sets.isEmpty }
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
    /// The plan this session was seeded from, stamped on every saved entry so
    /// Home can tell that *this plan* was completed today; `nil` for a free
    /// (unplanned) quick workout.
    private let planID: UUID?

    // MARK: Init
    init(store: WorkoutLogStoring) {
        self.store = store
        self.planID = nil
    }

    /// Seeds the session from a plan: each planned exercise becomes an item,
    /// prefilled from its targets or left pending for the user to log. Keeps
    /// the plan's `id` so finished entries record which plan they belong to.
    init(store: WorkoutLogStoring, plan: WorkoutPlan) {
        self.store = store
        self.planID = plan.id
        items = plan.exercises.compactMap(Self.draftItem(from:))
    }

    /// Maps a planned exercise to a session item. Returns `nil` when the
    /// exercise is no longer in the catalog.
    static func draftItem(from planned: PlannedExercise) -> DraftItem? {
        guard let exercise = ExerciseCatalog.exercise(withID: planned.exerciseID) else { return nil }
        return DraftItem(exercise: exercise, sets: prefilledSets(from: planned))
    }

    /// Target sets/reps become concrete sets to confirm; without both targets
    /// the item stays pending so the user logs it on the SetPad.
    static func prefilledSets(from planned: PlannedExercise) -> [LoggedSet] {
        guard let targetSets = planned.targetSets, targetSets > 0,
              let targetReps = planned.targetReps, targetReps > 0
        else { return [] }
        return Array(repeating: LoggedSet(reps: targetReps), count: targetSets)
    }

    // MARK: Derived state
    var isEmpty: Bool { items.isEmpty }
    /// Finishing needs at least one exercise with logged sets (pending items,
    /// seeded from a plan but never confirmed, are skipped).
    var canFinish: Bool { items.contains { !$0.isPending } }
    var exerciseCount: Int { items.count }
    var totalSets: Int { items.reduce(0) { $0 + $1.sets.count } }

    // MARK: Intentions
    /// Queues an exercise with the sets logged on the SetPad. Empty logs are
    /// ignored so the session never gains a set-less exercise this way.
    func addExercise(_ exercise: Exercise, sets: [LoggedSet]) {
        guard !sets.isEmpty else { return }
        items.append(DraftItem(exercise: exercise, sets: sets))
    }

    /// Replaces the sets on a queued item — used when the user confirms a
    /// pending plan exercise (or edits one) on the SetPad.
    func updateSets(itemID: UUID, sets: [LoggedSet]) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].sets = sets
    }

    func remove(_ item: DraftItem) {
        items.removeAll { $0.id == item.id }
    }

    /// Persists every logged exercise as one session (shared `sessionID` and a
    /// single timestamp). Pending items are skipped; no-op with nothing logged.
    func finish() {
        let logged = items.filter { !$0.isPending }
        guard !logged.isEmpty else { return }

        let date = Date.now
        let entries = logged.map { item in
            WorkoutLogEntry(
                exerciseID: item.exercise.id,
                date: date,
                sets: item.sets,
                sessionID: sessionID,
                planID: planID
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
