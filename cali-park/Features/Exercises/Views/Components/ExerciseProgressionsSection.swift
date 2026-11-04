import SwiftUI

// MARK: - ExerciseProgressionsSection
/// A concise link from a main movement to the progression ladders it belongs
/// to. It points at the ladder (where variants live in context) rather than
/// listing variants inline, keeping the detail screen uncluttered. Renders
/// nothing for movements no ladder references.
struct ExerciseProgressionsSection: View {
    let exercise: Exercise

    private var paths: [ProgressionPath] {
        ProgressionCatalog.paths(containing: exercise.id)
    }

    var body: some View {
        if !paths.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Progresje")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 8) {
                    ForEach(paths) { path in
                        NavigationLink(value: path.id) {
                            HStack(spacing: 12) {
                                ExerciseIconView(symbolName: path.symbolName, size: .row)

                                Text(path.name)
                                    .font(.bodyLarge)
                                    .foregroundStyle(Color.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(12)
                            .background(Color.componentBackground)
                            .clipShape(.rect(cornerRadius: AppRadius.medium))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Ścieżka: \(path.name)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
