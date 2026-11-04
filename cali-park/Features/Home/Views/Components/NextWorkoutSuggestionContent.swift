import SwiftUI

// MARK: - NextWorkoutSuggestionContent
/// No plan scheduled: the longest-untrained exercise and a button to log a set.
struct NextWorkoutSuggestionContent: View {
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

            Button("Zaloguj serię", action: onLog)
                .buttonStyle(.accent(.compact))
        }
    }
}
