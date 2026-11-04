import SwiftUI

// MARK: - SkillPathCard
/// One progression path in the grid: the current rung, its progress and
/// criterion, or "Ukończone".
struct SkillPathCard: View {
    let summary: SkillPathSummary

    @Environment(\.dynamicTypeSize) private var typeSize

    private var currentExercise: Exercise? {
        ExerciseCatalog.exercise(withID: summary.currentStep.exerciseID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExerciseIconView(symbolName: summary.path.symbolName, size: .row)

            Text(summary.path.name)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            if summary.state.isComplete {
                Label("Ukończone", systemImage: "checkmark.seal.fill")
                    .font(.bodySmall)
                    .foregroundStyle(Color.accent)
            } else {
                Text(currentExercise?.name ?? "")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    // Two lines tall side by side, so the bars of cards in one row
                    // line up whether the rung name wraps or not. Cards are alone
                    // in their row at accessibility sizes, so the name may wrap further.
                    .lineLimit(typeSize.isAccessibilitySize ? 4 : 2, reservesSpace: !typeSize.isAccessibilitySize)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgressView(value: summary.currentProgress.fractionComplete)
                    .tint(Color.accent)

                Text(MeasureFormat.criterion(for: summary.currentStep))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if summary.state.isComplete {
            return String(localized: "\(summary.path.name). Ukończone.")
        }
        let current = currentExercise?.name ?? ""
        let criterion = MeasureFormat.spokenCriterion(for: summary.currentStep)
        return String(localized: "\(summary.path.name). Teraz: \(current). Cel: \(criterion).")
    }
}
