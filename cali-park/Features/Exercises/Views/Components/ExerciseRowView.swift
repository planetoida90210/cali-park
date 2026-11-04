import SwiftUI

// MARK: - ExerciseRowView
struct ExerciseRowView: View {
    let exercise: Exercise
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    if isFavorite {
                        ExerciseFavoriteBadge()
                    }
                }

                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .contentShape(.rect(cornerRadius: AppRadius.medium))
    }

    /// Muscle groups; a favorite variant names its main movement instead.
    private var subtitle: String {
        if let parentID = exercise.variantOf, let parent = ExerciseCatalog.exercise(withID: parentID) {
            return String(localized: "Wariant: \(parent.name)")
        }
        return exercise.muscleGroups.map(\.displayName).joined(separator: " · ")
    }
}
