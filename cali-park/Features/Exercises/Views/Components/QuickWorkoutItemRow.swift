import SwiftUI

// MARK: - QuickWorkoutItemRow
/// One exercise of the workout: its sets so far and their total, or a prompt
/// to add sets for an exercise the plan prefilled.
struct QuickWorkoutItemRow: View {
    let item: QuickWorkoutViewModel.DraftItem

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: item.exercise.symbolName, size: .row)

            // At accessibility sizes the total moves under the name, so the
            // name keeps the full width instead of breaking mid-word.
            AdaptiveDetailRow {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.exercise.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    if item.isPending {
                        Text("Dotknij, aby dodać serie")
                            .font(.bodySmall)
                            .foregroundStyle(Color.accent)
                    } else {
                        Text(MeasureFormat.breakdown(of: item.sets))
                            .font(.bodySmall)
                            .monospacedDigit()
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            } details: {
                if item.isPending {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.accent)
                } else {
                    Text(MeasureFormat.total(of: item.sets))
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(item.isPending ? "Dotknij, aby dodać serie" : "Dotknij, aby edytować serie")
    }
}
