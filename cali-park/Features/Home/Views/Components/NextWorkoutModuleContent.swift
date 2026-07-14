import SwiftUI

// MARK: - Next Workout Module
/// Suggests the next exercise: a basic movement for the muscle group that has
/// gone untrained the longest. Empty journal — honest empty state instead of
/// a fake schedule.
struct NextWorkoutModuleContent: View {
    let dashboard: HomeDashboardViewModel

    /// Payload-driven sheet — set only when logging starts.
    @State private var loggingExercise: Exercise?

    var body: some View {
        Group {
            if let suggestion = dashboard.suggestedExercise {
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

            Text("Zaloguj pierwszy trening, a zaproponujemy kolejny.")
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
