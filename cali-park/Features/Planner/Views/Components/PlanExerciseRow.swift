import SwiftUI

// MARK: - PlanExerciseRow
struct PlanExerciseRow: View {
    let exercise: Exercise?
    /// What to do, e.g. "Para 1 · 3 × 5–8 · przerwa 90 s".
    var target: String?
    /// The ladder the item follows, for an item from a program.
    var ladder: String?

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(
                symbolName: exercise?.symbolName ?? ExerciseCatalog.unknownSymbolName,
                size: .row
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? ExerciseCatalog.unknownName)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                if let target {
                    Text(target)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                if let ladder {
                    Label("Podąża za Twoim szczeblem: \(ladder)", systemImage: "stairs")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
