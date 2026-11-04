import SwiftUI

// MARK: - StepDetailHeader
/// Top of the rung detail sheet: the exercise icon and its description.
struct StepDetailHeader: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .detail)

            Text(exercise.description)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
