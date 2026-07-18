import Foundation

// MARK: - HeroWorkoutSummary
/// Turns a `LatestWorkout` into one glanceable line, shared by the hero states
/// that celebrate or recall a session (completed today / free mode). Names come
/// from the static `ExerciseCatalog`, so the hero views stay "dumb" — they need
/// no view model to render a summary.
enum HeroWorkoutSummary {
    /// Session: "3 ćwiczenia · 68 powtórzeń". Single: "Podciągnięcia · 6 + 6 + 8"
    /// (or "Front lever · 3 × 20 s" for a timed exercise).
    static func headline(for workout: HomeDashboardViewModel.LatestWorkout) -> String {
        if workout.isSession {
            return "\(PolishPlural.exercises(workout.entries.count)) · \(SetLogFormat.totals(reps: workout.totalReps, seconds: workout.totalSeconds))"
        }
        guard let entry = workout.entries.first else { return "Trening" }
        let name = ExerciseCatalog.exercise(withID: entry.exerciseID)?.name ?? "Ćwiczenie"
        let breakdown = SetLogFormat.breakdown(of: entry.sets)
        return breakdown.isEmpty ? name : "\(name) · \(breakdown)"
    }
}
