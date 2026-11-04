import SwiftUI

// MARK: - HeroCompletedTodayView
/// Today's training is done. The hero switches to a calm celebration: what was
/// trained, then the weekly goal with its week streak. No CTA — the work is
/// finished.
struct HeroCompletedTodayView: View {
    let summary: WorkoutSession
    /// The weekly goal row; `nil` hides it (the goal could not be read).
    let weeklyGoal: WeeklyGoalSnapshot?
    /// Opens the goal editor (long press on the goal row).
    var onEditGoal: () -> Void = {}
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(now: now)

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

            if let weeklyGoal {
                Divider().overlay(Color.divider)

                HeroWeeklyGoalView(snapshot: weeklyGoal, onEdit: onEditGoal)
            }
        }
    }
}

// MARK: - Preview
#Preview("Zrobione dziś") {
    HeroCompletedTodayView(
        summary: WorkoutSession(
            id: UUID(),
            date: .now,
            entries: [
                WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)], sessionID: UUID()),
                WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, sets: [LoggedSet(reps: 12)], sessionID: UUID())
            ]
        ),
        weeklyGoal: WeeklyGoalPreview.running
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
