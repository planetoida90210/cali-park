import SwiftUI

// MARK: - ProgramItemRow
struct ProgramItemRow: View {
    let exercise: Exercise?
    let target: String?

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise?.symbolName ?? ExerciseCatalog.unknownSymbolName, size: .row)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? ExerciseCatalog.unknownName)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                if let target {
                    Text(target)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
