import SwiftUI

// MARK: - HeroPlanTodayView
/// Today has a plan that isn't done yet: the plan is the headline and a big
/// "Rozpocznij" is the one move to make. Any reps already logged today show as
/// quiet progress. A "dumb" view — the state is passed in, the tap is a closure.
struct HeroPlanTodayView: View {
    let plan: WorkoutPlan
    let loggedTodayReps: Int
    let name: String
    var now: Date = .now
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(name: name, now: now)

                Text(plan.name)
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)

                Text("Plan na dziś · \(PolishPlural.exercises(plan.exerciseCount))")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)

                if loggedTodayReps > 0 {
                    Text("Zaczęte dziś: \(PolishPlural.reps(loggedTodayReps))")
                        .font(.bodySmall)
                        .foregroundStyle(Color.accent)
                        .contentTransition(.numericText())
                }
            }
            .accessibilityElement(children: .combine)

            Button(action: onStart) {
                HStack(spacing: 8) {
                    playIcon
                    Text("Rozpocznij")
                }
            }
            .buttonStyle(HeroPrimaryButtonStyle())
        }
    }

    /// A gentle, looping pulse to draw the eye to the primary action. Static
    /// when the user prefers reduced motion.
    @ViewBuilder
    private var playIcon: some View {
        let icon = Image(systemName: "play.fill").accessibilityHidden(true)
        if reduceMotion {
            icon
        } else {
            icon.phaseAnimator([false, true]) { view, pulsing in
                view.scaleEffect(pulsing ? 1.12 : 1)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
        }
    }
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
        name: "Michał",
        onStart: {}
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
