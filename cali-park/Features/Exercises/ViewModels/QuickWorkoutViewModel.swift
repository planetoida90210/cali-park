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
    }

    // MARK: State
    private(set) var items: [DraftItem] = []
    var errorMessage: String?
    /// Set after a successful save so the session screen can dismiss itself.
    private(set) var didFinish = false

    // MARK: Dependencies
    private let journal: TrainingJournal
    /// Shared identifier stamped on every entry saved from this session.
    private let sessionID = UUID()
    /// The plan this session was seeded from, stamped on every saved entry so
    /// Home can tell that *this plan* was completed today; `nil` for a free
    /// (unplanned) quick workout.
    private let planID: UUID?
    /// The items the session opened with (a plan's seeded exercises, or none),
    /// so leaving untouched never asks to discard anything.
    private let initialItems: [DraftItem]
    /// Wall-clock source for the time a finished session is stamped with.
    private let clock: () -> Date

    /// The screen title: the plan's name for a workout started from a plan,
    /// otherwise "Szybki trening".
    let title: String

    // MARK: Init
    init(journal: TrainingJournal, clock: @escaping () -> Date) {
        self.journal = journal
        self.clock = clock
        self.planID = nil
        self.initialItems = []
        self.title = String(localized: "Szybki trening")
    }

    /// Seeds the session from a plan: each planned exercise becomes an item,
    /// prefilled from its targets or left pending for the user to log. Keeps
    /// the plan's `id` so finished entries record which plan they belong to.
    ///
    /// With `pathStates`, items that follow a ladder (from a ready-made
    /// program) train the athlete's current rung instead of the one they were
    /// created on, and `logs` drive the "+1 rep" prefill. Without them, every
    /// item trains its stored exercise.
    init(journal: TrainingJournal,
         plan: WorkoutPlan,
         pathStates: [ProgressionPathID: PathState]? = nil,
         logs: [WorkoutLogEntry] = [],
         clock: @escaping () -> Date) {
        self.journal = journal
        self.clock = clock
        self.planID = plan.id
        let name = plan.name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = name.isEmpty ? String(localized: "Szybki trening") : name
        let seeded = plan.exercises.compactMap { Self.draftItem(from: $0, pathStates: pathStates, logs: logs) }
        self.items = seeded
        self.initialItems = seeded
    }

    /// Maps a planned exercise to a session item, moving a ladder item to the
    /// current rung when `pathStates` are known. Returns `nil` when the
    /// exercise is no longer in the catalog.
    static func draftItem(from planned: PlannedExercise,
                          pathStates: [ProgressionPathID: PathState]? = nil,
                          logs: [WorkoutLogEntry] = []) -> DraftItem? {
        let resolved = pathStates.map { ProgramPrescriber.resolved(planned, pathStates: $0) } ?? planned
        guard let exercise = ExerciseCatalog.exercise(withID: resolved.exerciseID) else { return nil }
        return DraftItem(exercise: exercise,
                         sets: prefilledSets(from: resolved, measurement: exercise.measurement, logs: logs))
    }

    /// Target sets become concrete sets to confirm, in the exercise's unit:
    /// reps for a rep exercise, seconds held for a hold (audit A-8). A range
    /// prefills its bottom, or one rep more than the last session (see
    /// `ProgramPrescriber.suggestedValue`). Without a set count and a value
    /// the item stays pending so the user logs it on the SetPad.
    static func prefilledSets(from planned: PlannedExercise,
                              measurement: ExerciseMeasurement = .reps,
                              logs: [WorkoutLogEntry] = []) -> [LoggedSet] {
        guard let targetSets = planned.targetSets, targetSets > 0 else { return [] }
        var target = planned
        // A hold planned before hold targets existed carries its seconds in
        // `targetReps`.
        if measurement == .seconds, target.targetSeconds == nil {
            target.targetSeconds = target.targetReps
        }
        guard let value = ProgramPrescriber.suggestedValue(for: target, measurement: measurement, logs: logs),
              value > 0
        else { return [] }
        return Array(repeating: LoggedSet(value: value, measurement: measurement), count: targetSets)
    }

    // MARK: Derived state
    var isEmpty: Bool { items.isEmpty }
    /// Finishing needs at least one exercise with logged sets (pending items,
    /// seeded from a plan but never confirmed, are skipped).
    var canFinish: Bool { items.contains { !$0.isPending } }
    var exerciseCount: Int { items.count }
    var totalSets: Int { items.reduce(0) { $0 + $1.sets.count } }
    /// The saved workout's identifier once `finish()` succeeded, so the screen
    /// can push its summary; `nil` before that.
    var savedSessionID: UUID? { didFinish ? sessionID : nil }
    /// Whether closing now would lose something the user entered: the items
    /// differ from what the session opened with, and nothing is saved yet.
    var hasUnsavedChanges: Bool { !didFinish && items != initialItems }

    /// The summary of the workout just saved, read back from the journal so
    /// it shows exactly what was persisted.
    func makeSummaryViewModel() -> WorkoutSessionDetailViewModel {
        WorkoutSessionDetailViewModel(sessionID: sessionID, journal: journal)
    }

    // MARK: Intentions
    /// Queues an exercise with the sets logged on the SetPad. Empty logs are
    /// ignored so the session never gains a set-less exercise this way. The
    /// same exercise may be added more than once (supersets); progress merges
    /// a workout's entries per exercise, so every set counts (audit A-5).
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
    /// single timestamp). Pending items are skipped; no-op with nothing logged
    /// or once saved, so a double tap can't save the session twice (D-15).
    func finish() {
        guard !didFinish else { return }
        let logged = items.filter { !$0.isPending }
        guard !logged.isEmpty else { return }

        let date = clock()
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
            try journal.logSession(entries)
            didFinish = true
        } catch {
            errorMessage = TrainingJournal.saveFailureMessage
        }
    }
}
