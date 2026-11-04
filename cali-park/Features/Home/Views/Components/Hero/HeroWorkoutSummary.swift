import Foundation

// MARK: - HeroWorkoutSummary
/// Turns a `WorkoutSession` into one glanceable line, shared by the hero states
/// that celebrate or recall a session (completed today / free mode) and the
/// Home "Ostatni trening" card. Names come from the static `ExerciseCatalog`,
/// so the views stay "dumb" — they need no view model to render a summary.
enum HeroWorkoutSummary {
    /// Session: "3 ćwiczenia · 68 powtórzeń". Single: "Podciągnięcia · 6 + 6 + 8"
    /// (or "Front lever · 3 × 20 s" for a timed exercise).
    static func headline(for workout: WorkoutSession) -> String {
        if workout.isSession {
            return MeasureFormat.summary(of: workout)
        }
        guard let entry = workout.entries.first else { return String(localized: "Trening") }
        let name = ExerciseCatalog.exercise(withID: entry.exerciseID)?.name ?? String(localized: "Ćwiczenie")
        let breakdown = MeasureFormat.breakdown(of: entry.sets)
        return breakdown.isEmpty ? name : "\(name) · \(breakdown)"
    }
}
