import SwiftUI

// MARK: - HeroFreeModeView
/// No plans, but a history to build on. The hero recalls the last workout,
/// keeps the streak in view, and — when the heuristic has one — suggests what
/// to train next. Acting on it is one tap away in the permanent rail below
/// ("Szybki trening" / "Plany"), so the card informs rather than repeats it.
struct HeroFreeModeView: View {
    let lastWorkout: HomeDashboardViewModel.LatestWorkout
    let suggestion: Exercise?
    let streak: WorkoutStreak
    let name: String
    let weeklyReps: Int
    let weeklyProgress: Double
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(name: name, now: now)

                Text("Trenuj po swojemu")
                    .font(.title2)
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

            HeroStreakLabel(streak: streak)

            Divider().overlay(Color.divider)

            HeroWeeklyRingView(weeklyReps: weeklyReps, progress: weeklyProgress)
        }
    }
}

// MARK: - Preview
#Preview("Wolny tryb") {
    HeroFreeModeView(
        lastWorkout: HomeDashboardViewModel.LatestWorkout(
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
            entries: [WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 7)])]
        ),
        suggestion: ExerciseCatalog.exercise(withID: ExerciseCatalog.squatsID),
        streak: WorkoutStreak(current: 0, longest: 6, trainedDays: []),
        name: "Michał",
        weeklyReps: 15,
        weeklyProgress: 0.25
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
