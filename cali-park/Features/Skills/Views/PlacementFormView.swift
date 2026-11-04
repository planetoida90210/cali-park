import SwiftUI

// MARK: - PlacementFormView
/// The placement questionnaire: a few rep-count questions, a handful of
/// "can you already do this?" checkboxes. The resistance band is not asked
/// here (ticket 026): it stays a visible option on the ladder, and a band
/// declared earlier is kept on save.
///
/// Shared by onboarding (SK4) and the in-app calibration sheet so the two never
/// drift apart. It lays out sections only — the caller supplies the scroll
/// container and any title — so it drops cleanly into a paged onboarding screen
/// or a navigation sheet.
struct PlacementFormView: View {
    @Bindable var viewModel: PlacementCalibrationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(viewModel.repQuestions) { question in
                repQuestionSection(question)
            }
            skillSection
        }
    }

    // MARK: Rep questions
    private func repQuestionSection(_ question: RepCountQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 8) {
                ForEach(RepCountBucket.allCases) { bucket in
                    bucketButton(bucket, for: question)
                }
            }

            // A saved level no single bucket stands for (e.g. 1–5 and 6–11
            // both lead to it) is kept as is unless the athlete answers again.
            if let savedRung = viewModel.savedRungName(for: question) {
                Text("Zapisany poziom: \(savedRung)")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private func bucketButton(_ bucket: RepCountBucket, for question: RepCountQuestion) -> some View {
        let isSelected = viewModel.bucket(for: question) == bucket
        return Button {
            viewModel.select(bucket, for: question)
        } label: {
            Text(bucket.label)
                .font(.buttonMedium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(isSelected ? Color.black : Color.textPrimary)
                .background(isSelected ? Color.accent : Color.componentBackground)
                .clipShape(.rect(cornerRadius: AppRadius.medium))
        }
        .accessibilityLabel("\(question.prompt) \(bucket.label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Skills
    private var skillSection: some View {
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

// MARK: - Preview
#Preview {
    ScrollView {
        PlacementFormView(
            viewModel: PlacementCalibrationViewModel(store: InMemorySkillPlacementStore())
        )
        .padding(16)
    }
    .background(Color.appBackground.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
