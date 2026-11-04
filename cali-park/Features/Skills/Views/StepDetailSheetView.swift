import SwiftUI

// MARK: - StepDetailSheetView
/// One rung, up close: the exercise's technique, the target with the athlete's
/// logged best, the equipment it needs, and a "Trenuj" button that opens the
/// SetPad in the right measure (reps or seconds) for this exercise.
///
/// Presented from `PathDetailView`. The ladder is a map, never a gate, so this
/// opens for any rung — conquered, current, or future.
///
/// Progress is read live from the shared snapshot, so a set saved through
/// "Trenuj" shows in "Twoje najlepsze" as soon as the SetPad closes (audit
/// A-12, E-19), and a conquered rung celebrates over this sheet.
struct StepDetailSheetView: View {
    let exercise: Exercise
    let step: ProgressionStep
    let viewModel: SkillPathsViewModel
    let environment: AppEnvironment

    private var progress: RungProgress { viewModel.rungProgress(for: step) }

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
        .rewardOverlay()
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

            Text(MeasureFormat.criterion(for: step))
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            if let note = step.criterionNote {
                Text(note)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }

            if step.unilateralSide != nil {
                Text("Wpisz wynik słabszej strony.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            if let best = MeasureFormat.best(progress) {
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

            Text(step.criterionSource.sourceLine.keptTogether)
                .font(.bodySmall)
                .foregroundStyle(Color.textTertiary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityCriterion)
        .accessibilityValue(accessibilityProgress)
    }

    private var accessibilityCriterion: String {
        var parts = ["Cel: \(MeasureFormat.spokenCriterion(for: step))"]
        if let note = step.criterionNote { parts.append(note) }
        if step.unilateralSide != nil { parts.append("Wpisz wynik słabszej strony") }
        parts.append("Źródło: \(step.criterionSource.explanation)")
        return parts.joined(separator: ". ")
    }

    private var accessibilityProgress: String {
        guard let best = MeasureFormat.best(progress) else {
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

            if let tip = step.tip {
                Text("Wskazówka: \(tip)")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
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
    let step = path.steps[3]
    let environment = AppEnvironment.seeded(logs: [
        WorkoutLogEntry(exerciseID: step.exerciseID, sets: Array(repeating: LoggedSet(reps: 6), count: 3))
    ])
    return Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            StepDetailSheetView(
                exercise: ExerciseCatalog.exercise(withID: step.exerciseID)!,
                step: step,
                viewModel: environment.makeSkillPathsViewModel(),
                environment: environment
            )
            .environment(environment.rewardCenter)
            .preferredColorScheme(.dark)
        }
}
