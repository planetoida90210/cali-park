import SwiftUI

// MARK: - PlacementSkillSection
/// The "Opanowane ruchy" section of the placement form: a checkbox row for
/// each skill the athlete may already do.
struct PlacementSkillSection: View {
    let viewModel: PlacementCalibrationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opanowane ruchy")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Zaznacz te, które już robisz.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 8) {
                ForEach(viewModel.skillQuestions) { question in
                    skillRow(question)
                }
            }
        }
    }

    private func skillRow(_ question: SkillQuestion) -> some View {
        let isMastered = viewModel.isMastered(question)
        return Button {
            viewModel.toggleMastery(of: question)
        } label: {
            HStack {
                Text(question.label)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: isMastered ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isMastered ? Color.accent : Color.textTertiary)
            }
            .padding()
            .background(Color.componentBackground)
            .clipShape(.rect(cornerRadius: AppRadius.medium))
        }
        .accessibilityLabel(question.label)
        .accessibilityAddTraits(isMastered ? .isSelected : [])
    }
}
