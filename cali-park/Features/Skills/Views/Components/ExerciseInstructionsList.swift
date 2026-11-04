import SwiftUI

// MARK: - ExerciseInstructionsList
/// The "Jak wykonać" steps, numbered — shared shape with the exercise detail
/// screen so technique reads the same everywhere.
struct ExerciseInstructionsList: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jak wykonać")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.bodyMedium)
                            .monospacedDigit()
                            .foregroundStyle(Color.accent)

                        Text(steps[index])
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if index < steps.count - 1 {
                        Divider()
                            .overlay(Color.divider)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.componentBackground)
            .clipShape(.rect(cornerRadius: AppRadius.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
