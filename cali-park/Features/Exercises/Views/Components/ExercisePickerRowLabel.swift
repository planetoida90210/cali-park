import SwiftUI

// MARK: - ExercisePickerRowLabel
/// Card-style label shared by the picker list and the variant list: icon,
/// name, one subtitle line, and a trailing hint — a chevron when tapping opens
/// the variant list, a plus when it adds the exercise.
struct ExercisePickerRowLabel: View {
    let exercise: Exercise
    let subtitle: String
    let opensVariants: Bool

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

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
        .clipShape(.rect(cornerRadius: 12))
        .contentShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    ExercisePickerRowLabel(
        exercise: ExerciseCatalog.all[0],
        subtitle: "Plecy · Ramiona",
        opensVariants: true
    )
    .padding(16)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
