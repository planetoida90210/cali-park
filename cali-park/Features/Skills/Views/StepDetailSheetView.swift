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
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if Self.inlineTitle(exercise.name, typeSize: typeSize).isEmpty {
                        Text(exercise.name)
                            .font(.appTitle2)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .accessibilityAddTraits(.isHeader)
                    }
                    StepDetailHeader(exercise: exercise)
                    StepCriterionCard(step: step, progress: progress)
                    StepEquipmentRow(step: step)
                    ExerciseInstructionsList(steps: exercise.instructions)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Self.inlineTitle(exercise.name, typeSize: typeSize))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                StepTrainButton(onTrain: { loggingExercise = exercise })
            }
            .sheet(item: $loggingExercise) { exercise in
                SetPadSheetView(viewModel: environment.makeWorkoutLogViewModel(exercise: exercise))
            }
        }
        .rewardOverlay()
    }

    /// The navigation bar's title: the exercise name, or nothing at
    /// accessibility sizes, where the inline title would cut a long name
    /// ("Wiosłowanie na podwyż…") and the name heads the content instead.
    static func inlineTitle(_ name: String, typeSize: DynamicTypeSize) -> String {
        typeSize.isAccessibilitySize ? "" : name
    }
}

#if DEBUG
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
#endif
