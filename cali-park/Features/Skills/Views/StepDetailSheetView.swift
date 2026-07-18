import SwiftUI

// MARK: - StepDetailSheetView
/// One rung, up close: the exercise's technique, the target with the athlete's
/// logged best, the equipment it needs, and a "Trenuj" button that opens the
/// SetPad in the right measure (reps or seconds) for this exercise.
///
/// Presented from `PathDetailView`. The ladder is a map, never a gate, so this
/// opens for any rung — conquered, current, or future.
struct StepDetailSheetView: View {
    let exercise: Exercise
    let step: ProgressionStep
    let progress: RungProgress
    let environment: AppEnvironment

    /// Payload-driven: the SetPad opens only when an exercise is set.
    @State private var loggingExercise: Exercise?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    criterionCard
                    equipmentRow
                    ExerciseInstructionsList(steps: exercise.instructions)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                trainButton
            }
            .sheet(item: $loggingExercise) { exercise in
                SetPadSheetView(viewModel: environment.makeWorkoutLogViewModel(exercise: exercise))
            }
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .detail)

            Text(exercise.description)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Criterion
    private var criterionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cel")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            Text(ProgressionFormat.criterion(step.criterion))
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            if let best = ProgressionFormat.best(progress) {
                Text("Twoje najlepsze: \(best)")
                    .font(.bodyMedium)
                    .foregroundStyle(progress.isMet ? Color.accent : Color.textSecondary)
            } else {
                Text("Zaloguj serię, aby zmierzyć postęp.")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }

            ProgressView(value: progress.fractionComplete)
                .tint(Color.accent)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cel: \(ProgressionFormat.spokenCriterion(step.criterion))")
        .accessibilityValue(accessibilityProgress)
    }

    private var accessibilityProgress: String {
        guard let best = ProgressionFormat.best(progress) else {
            return "Brak zapisów"
        }
        return progress.isMet ? "Zaliczone, \(best)" : "Twoje najlepsze: \(best)"
    }

    // MARK: Equipment
    private var equipmentRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sprzęt")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            Text(ProgressionFormat.equipment(step.equipment))
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Train CTA
    private var trainButton: some View {
        Button {
            loggingExercise = exercise
        } label: {
            Text("Trenuj")
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
}

// MARK: - ExerciseInstructionsList
/// The "Jak wykonać" steps, numbered — shared shape with the exercise detail
/// screen so technique reads the same everywhere.
private struct ExerciseInstructionsList: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jak wykonać")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.bodyMedium)
                            .monospacedDigit()
                            .foregroundStyle(Color.accent)

                        Text(steps[index])
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

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

// MARK: - Preview
#Preview {
    let path = ProgressionCatalog.path(withID: .pullUp)!
    let step = path.steps[4]
    return Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            StepDetailSheetView(
                exercise: ExerciseCatalog.exercise(withID: step.exerciseID)!,
                step: step,
                progress: RungProgress(criterion: step.criterion, bestValue: 6),
                environment: .preview
            )
            .preferredColorScheme(.dark)
        }
}
