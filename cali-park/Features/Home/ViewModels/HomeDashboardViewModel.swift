import Foundation
import Observation

// MARK: - HomeDashboardViewModel
/// Feeds the Home modules (Quick Log, streak, next workout, hero card) from
/// the same `WorkoutLogStoring` the Exercises tab writes to. Reload on appear
/// picks up entries saved while another tab was active.
@MainActor
@Observable
final class HomeDashboardViewModel {
    // MARK: State
    private(set) var entries: [WorkoutLogEntry] = []

    // MARK: Dependencies
    private let store: WorkoutLogStoring

    // MARK: Init
    init(store: WorkoutLogStoring) {
        self.store = store
        reload()
    }

    // MARK: Intentions
    func reload() {
        entries = store.load().sorted { $0.date > $1.date }
    }

    /// SetPad session for logging straight from Home (Quick Log).
    func makeWorkoutLogViewModel(exercise: Exercise) -> WorkoutLogViewModel {
        WorkoutLogViewModel(exercise: exercise, store: store)
    }

    /// Quick workout session started from Home (Quick Log).
    func makeQuickWorkoutViewModel() -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(store: store)
    }

    // MARK: Quick Log
    var latestEntry: WorkoutLogEntry? {
        entries.first
    }

    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
    }

    /// The exercise Quick Log should open: the last logged one,
    /// falling back to pull-ups for a fresh journal.
    var quickLogExercise: Exercise {
        if let latestEntry, let exercise = exercise(for: latestEntry) {
            return exercise
        }
        return ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID) ?? ExerciseCatalog.all[0]
    }

    // MARK: Streak
    var streak: WorkoutStreak {
        WorkoutStreak.compute(from: entries.map(\.date))
    }

    // MARK: Hero card
    /// Pull-up reps logged in the current calendar week.
    var weeklyPullUps: Int {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return entries
            .filter { $0.exerciseID == ExerciseCatalog.pullUpsID && week.contains($0.date) }
            .reduce(0) { $0 + $1.totalReps }
    }

    // MARK: Next workout
    /// Heuristic suggestion: the muscle group that has gone untrained the
    /// longest (never-trained groups win), represented by a basic catalog
    /// exercise. `nil` until the journal has at least one entry.
    var suggestedExercise: Exercise? {
        guard !entries.isEmpty else { return nil }

        var lastTrained: [MuscleGroup: Date] = [:]
        for entry in entries {
            guard let exercise = exercise(for: entry) else { continue }
            for group in exercise.muscleGroups {
                lastTrained[group] = max(lastTrained[group] ?? .distantPast, entry.date)
            }
        }

        let staleGroups = MuscleGroup.allCases.sorted {
            (lastTrained[$0] ?? .distantPast) < (lastTrained[$1] ?? .distantPast)
        }

        for group in staleGroups {
            // Prefer a basic exercise that targets the group primarily.
            if let match = ExerciseCatalog.all.first(where: {
                $0.category == .basic && $0.muscleGroups.first == group
            }) {
                return match
            }
            if let match = ExerciseCatalog.all.first(where: {
                $0.category == .basic && $0.muscleGroups.contains(group)
            }) {
                return match
            }
        }
        return nil
    }
}
