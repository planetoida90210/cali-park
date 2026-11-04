import SwiftUI

// MARK: - ExerciseDetailHeader
struct ExerciseDetailHeader: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .detail)

            Text(exercise.category.displayName)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            Text(exercise.description)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
