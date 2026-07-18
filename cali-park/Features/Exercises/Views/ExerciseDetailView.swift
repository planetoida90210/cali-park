import SwiftUI

// MARK: - ExerciseDetailView
/// Detail screen for a catalog exercise: Watch-style icon, description,
/// muscle groups, equipment, step-by-step instructions and the
/// "Dodaj serię" entry point into the SetPad.
struct ExerciseDetailView: View {
    let exercise: Exercise
    let environment: AppEnvironment

    /// Payload-driven presentation: the sheet opens only when an exercise
    /// is set (never a bare `Bool` + separate state).
    @State private var loggingExercise: Exercise?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ExerciseDetailHeader(exercise: exercise)
                ExerciseMuscleGroupsRow(groups: exercise.muscleGroups)

                if !exercise.equipment.isEmpty {
                    ExerciseEquipmentRow(equipment: exercise.equipment)
                }

                ExerciseInstructionsCard(steps: exercise.instructions)

                ExerciseProgressionsSection(exercise: exercise)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                loggingExercise = exercise
            } label: {
                Text("Dodaj serię")
                    .font(.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accent)
                    .foregroundStyle(Color.black)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color.appBackground.opacity(0.9))
        }
        .sheet(item: $loggingExercise) { exercise in
            SetPadSheetView(viewModel: environment.makeWorkoutLogViewModel(exercise: exercise))
        }
    }
}

// MARK: - ExerciseDetailHeader
private struct ExerciseDetailHeader: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .detail)

            Text(exercise.category.displayName)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            Text(exercise.description)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ExerciseMuscleGroupsRow
private struct ExerciseMuscleGroupsRow: View {
    let groups: [MuscleGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grupy mięśniowe")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(groups) { group in
                    Text(group.displayName)
                        .font(.bodySmall)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color.componentBackground)
                        .foregroundStyle(Color.textPrimary)
                        .clipShape(.capsule)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ExerciseEquipmentRow
private struct ExerciseEquipmentRow: View {
    let equipment: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sprzęt")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            Text(equipment.joined(separator: " · "))
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ExerciseProgressionsSection
/// A concise link from a main movement to the progression ladders it belongs
/// to. It points at the ladder (where variants live in context) rather than
/// listing variants inline, keeping the detail screen uncluttered. Renders
/// nothing for movements no ladder references.
private struct ExerciseProgressionsSection: View {
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
                            .clipShape(.rect(cornerRadius: 12))
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

// MARK: - ExerciseInstructionsCard
private struct ExerciseInstructionsCard: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jak wykonać")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

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
            .clipShape(.rect(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ExerciseInstructionRow
private struct ExerciseInstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.bodyMedium)
                .monospacedDigit()
                .foregroundStyle(Color.accent)

            Text(text)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: ExerciseCatalog.all[0], environment: .preview)
    }
    .preferredColorScheme(.dark)
}
