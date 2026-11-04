import SwiftUI

// MARK: - HeroFreeModeView
/// No plans, but a history to build on. The hero recalls the last workout,
/// shows the weekly goal, and — when the heuristic has one — suggests what
/// to train next. Acting on it is one tap away in the permanent rail below
/// ("Szybki trening" / "Plany"), so the card informs rather than repeats it.
struct HeroFreeModeView: View {
    let lastWorkout: WorkoutSession
    let suggestion: Exercise?
    /// The weekly goal row; `nil` hides it (the goal could not be read).
    let weeklyGoal: WeeklyGoalSnapshot?
    /// Opens the goal editor (long press on the goal row).
    var onEditGoal: () -> Void = {}
    /// A one-line progression nudge, or `nil` when no rung is partway done.
    var progressionHint: String? = nil
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(now: now)

                Text("Trenuj po swojemu")
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)

                Text("Ostatnio: \(HeroWorkoutSummary.headline(for: lastWorkout))")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)

                if let suggestion {
                    Text("Na dziś proponuję: \(suggestion.name)")
                        .font(.bodySmall)
                        .foregroundStyle(Color.accent)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)

            if let progressionHint {
                HeroProgressionHintView(hint: progressionHint)
            }

            if let weeklyGoal {
                Divider().overlay(Color.divider)

                HeroWeeklyGoalView(snapshot: weeklyGoal, onEdit: onEditGoal)
            }
        }
    }
}

// MARK: - Preview
#Preview("Wolny tryb") {
    HeroFreeModeView(
        lastWorkout: WorkoutSession(
            id: UUID(),
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
            entries: [WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 7)])]
        ),
        suggestion: ExerciseCatalog.exercise(withID: ExerciseCatalog.squatsID),
        weeklyGoal: WeeklyGoalPreview.running,
        progressionHint: "Jeszcze 2 powtórzenia do 3 × 8 — następny szczebel: Pełne podciągnięcia"
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
