import SwiftUI

// MARK: - HeroCompletedTodayView
/// Today's training is done. The hero switches to a calm celebration: what was
/// trained, the streak it kept alive, and the weekly goal demoted to a
/// secondary line. No CTA — the work is finished.
struct HeroCompletedTodayView: View {
    let summary: HomeDashboardViewModel.LatestWorkout
    let streak: WorkoutStreak
    let name: String
    let weeklyReps: Int
    let weeklyProgress: Double
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(name: name, now: now)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                        .accessibilityHidden(true)

                    Text("Zrobione na dziś")
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)
                }

                Text(HeroWorkoutSummary.headline(for: summary))
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            HeroStreakLabel(streak: streak)

            Divider().overlay(Color.divider)

            HeroWeeklyRingView(weeklyReps: weeklyReps, progress: weeklyProgress)
        }
    }
}

// MARK: - Preview
#Preview("Zrobione dziś") {
    HeroCompletedTodayView(
        summary: HomeDashboardViewModel.LatestWorkout(
            date: .now,
            entries: [
                WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)], sessionID: UUID()),
                WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, sets: [LoggedSet(reps: 12)], sessionID: UUID())
            ]
        ),
        streak: WorkoutStreak(current: 5, longest: 9, trainedDays: []),
        name: "Michał",
        weeklyReps: 42,
        weeklyProgress: 0.6
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
