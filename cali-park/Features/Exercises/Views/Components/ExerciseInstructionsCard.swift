import SwiftUI

// MARK: - ExerciseInstructionsCard
struct ExerciseInstructionsCard: View {
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
                    ExerciseInstructionRow(number: index + 1, text: steps[index])

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
