import SwiftUI

// MARK: - HeroPlanTodayView
/// Today has a plan that isn't done yet: the plan is the headline and a big
/// "Rozpocznij" is the one move to make. Any reps or holds logged today show as
/// quiet progress, and the weekly goal sits below the button. A "dumb" view —
/// the state is passed in, the taps are closures.
struct HeroPlanTodayView: View {
    let plan: WorkoutPlan
    let loggedTodayReps: Int
    /// Seconds held today, kept apart from reps.
    var loggedTodaySeconds: Int = 0
    /// The weekly goal row; `nil` hides it (the goal could not be read).
    var weeklyGoal: WeeklyGoalSnapshot? = nil
    /// Opens the goal editor (long press on the goal row).
    var onEditGoal: () -> Void = {}
    var now: Date = .now
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(now: now)

                Text(plan.name)
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)

                Text("Plan na dziś · \(PolishPlural.exercises(plan.exerciseCount))")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)

                if loggedTodayReps > 0 || loggedTodaySeconds > 0 {
                    Text("Zaczęte dziś: \(MeasureFormat.totals(reps: loggedTodayReps, seconds: loggedTodaySeconds))")
                        .font(.bodySmall)
                        .foregroundStyle(Color.accent)
                        .contentTransition(.numericText())
                }
            }
            .accessibilityElement(children: .combine)

            Button(action: onStart) {
                HStack(spacing: 8) {
                    HeroPlayIcon()
                    Text("Rozpocznij")
                }
            }
            .buttonStyle(.accent)

            if let weeklyGoal {
                Divider().overlay(Color.divider)

                HeroWeeklyGoalView(snapshot: weeklyGoal, onEdit: onEditGoal)
            }
        }
    }

    /// How many times "Rozpocznij" pulses after it appears.
    static let pulseBeats = 3
}

// MARK: - Preview
#Preview("Plan dziś") {
    HeroPlanTodayView(
        plan: WorkoutPlan(name: "Push Day", exercises: [
            PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID),
            PlannedExercise(exerciseID: ExerciseCatalog.dipsID),
            PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)
        ]),
        loggedTodayReps: 24,
        weeklyGoal: WeeklyGoalPreview.running,
        onStart: {}
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: AppRadius.medium))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
