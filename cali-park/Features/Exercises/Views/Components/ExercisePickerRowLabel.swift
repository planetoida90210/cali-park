import SwiftUI

// MARK: - ExercisePickerRowLabel
/// Card-style label shared by the picker list and the variant list: icon,
/// name, one subtitle line, and a trailing hint — a chevron when tapping opens
/// the variant list, a plus when it adds the exercise. A favorite carries a
/// small star after its name.
struct ExercisePickerRowLabel: View {
    let exercise: Exercise
    let subtitle: String
    let opensVariants: Bool
    var isFavorite = false

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
            // The row is a button's label, which would center wrapped lines.
            .multilineTextAlignment(.leading)

            Spacer()

            if opensVariants {
                Image(systemName: "chevron.right")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)
            }
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .contentShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    ExercisePickerRowLabel(
        exercise: ExerciseCatalog.all[0],
        subtitle: "Plecy · Ramiona",
        opensVariants: true,
        isFavorite: true
    )
    .padding(16)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
