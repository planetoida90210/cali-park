import SwiftUI

// MARK: - PlacementRepQuestionSection
/// One rep-count question of the placement form: the prompt, a row of bucket
/// buttons, and the saved level when no bucket stands for it.
struct PlacementRepQuestionSection: View {
    let viewModel: PlacementCalibrationViewModel
    let question: RepCountQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 8) {
                ForEach(RepCountBucket.allCases) { bucket in
                    bucketButton(bucket)
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

    private func bucketButton(_ bucket: RepCountBucket) -> some View {
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
}
