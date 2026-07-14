import SwiftUI

// MARK: - Next Workout Module
/// Shows what to train next. A scheduled plan wins (name, when, and a
/// "Rozpocznij" that opens the session prefilled from the plan); otherwise it
/// falls back to the untrained-group suggestion, then an honest empty state.
struct NextWorkoutModuleContent: View {
    let dashboard: HomeDashboardViewModel

    /// Payload-driven sheets — set only when an action starts.
    @State private var loggingExercise: Exercise?
    @State private var startingPlan: WorkoutPlan?

    var body: some View {
        Group {
            if let planned = dashboard.nextPlannedWorkout {
                PlannedWorkoutContent(planned: planned) {
                    startingPlan = planned.plan
                }
            } else if let suggestion = dashboard.suggestedExercise {
                SuggestionContent(exercise: suggestion) {
                    loggingExercise = suggestion
                }
            } else {
                NextWorkoutEmptyState()
            }
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .sheet(item: $loggingExercise, onDismiss: { dashboard.reload() }) { exercise in
            SetPadSheetView(viewModel: dashboard.makeWorkoutLogViewModel(exercise: exercise))
        }
        .sheet(item: $startingPlan, onDismiss: { dashboard.reload() }) { plan in
            QuickWorkoutView(
                viewModel: dashboard.makeQuickWorkoutViewModel(plan: plan),
                onFinish: { dashboard.reload() }
            )
        }
    }
}

// MARK: - PlannedWorkoutContent
private struct PlannedWorkoutContent: View {
    let planned: HomeDashboardViewModel.PlannedWorkout
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(planned.plan.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(WorkoutScheduleFormatter.dayLabel(planned.date)) · \(PolishPlural.exercises(planned.plan.exerciseCount))")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()
            }

            Button(action: onStart) {
                Text("Rozpocznij")
                    .font(.buttonMedium)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
    }
}

// MARK: - SuggestionContent
private struct SuggestionContent: View {
    let exercise: Exercise
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ExerciseIconView(symbolName: exercise.symbolName, size: .row)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("Najdłużej nietrenowane: \(exercise.muscleGroups.map(\.displayName).joined(separator: ", "))")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()
            }

            Button(action: onLog) {
                Text("Zaloguj serię")
                    .font(.buttonMedium)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
    }
}

// MARK: - NextWorkoutEmptyState
private struct NextWorkoutEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.title2)
                .foregroundStyle(Color.textSecondary)

            Text("Brak propozycji")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zaloguj pierwszy trening lub zaplanuj kolejny.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    NextWorkoutModuleContent(dashboard: AppEnvironment.preview.makeHomeDashboardViewModel())
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
