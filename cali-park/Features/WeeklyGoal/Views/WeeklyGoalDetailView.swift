import SwiftUI

// MARK: - WeeklyGoalDetailView
/// Edits one goal of the editor's draft: its kind and its target.
struct WeeklyGoalDetailView: View {
    let viewModel: WeeklyGoalEditorViewModel
    let goalID: WeeklyGoal.ID

    @State private var isPickingExercise = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let goal = viewModel.goal(withID: goalID) {
            Form {
                Section {
                    Picker("Rodzaj celu", selection: kindBinding(goal)) {
                        ForEach(WeeklyGoal.Kind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                }

                WeeklyGoalTargetSection(
                    metric: goal.metric,
                    onChange: { viewModel.updateMetric($0, forGoal: goalID) },
                    onPickExercise: { isPickingExercise = true }
                )

                if !viewModel.isPrimary(goalID) {
                    Section {
                        Button("Ustaw jako główny", systemImage: "star") { viewModel.makePrimary(goalID) }
                    }
                }

                if viewModel.canRemoveGoals {
                    Section {
                        Button("Usuń cel", systemImage: "trash", role: .destructive) {
                            viewModel.removeGoal(goalID)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(goal.metric.kind.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPickingExercise) {
                ExercisePickerSheet { exercise in
                    viewModel.updateMetric(Self.volume(for: exercise, keeping: goal.metric), forGoal: goalID)
                    isPickingExercise = false
                }
            }
        } else {
            ContentUnavailableView("Cel usunięty", systemImage: "target")
        }
    }

    private func kindBinding(_ goal: WeeklyGoal) -> Binding<WeeklyGoal.Kind> {
        Binding(
            get: { goal.metric.kind },
            set: { kind in
                guard kind != goal.metric.kind else { return }
                viewModel.updateMetric(kind.defaultMetric, forGoal: goalID)
            }
        )
    }

    /// A volume goal for `exercise`, keeping the amount when the unit stays.
    static func volume(for exercise: Exercise, keeping metric: WeeklyGoal.Metric) -> WeeklyGoal.Metric {
        if case let .exerciseVolume(_, measurement, amount) = metric, measurement == exercise.measurement {
            return .exerciseVolume(exerciseID: exercise.id, measurement: measurement, amount: amount)
        }
        let amount = exercise.measurement == .seconds ? 120 : 50
        return .exerciseVolume(exerciseID: exercise.id, measurement: exercise.measurement, amount: amount)
    }
}

// MARK: - WeeklyGoalTargetSection
/// The target controls for one metric kind.
private struct WeeklyGoalTargetSection: View {
    let metric: WeeklyGoal.Metric
    let onChange: (WeeklyGoal.Metric) -> Void
    let onPickExercise: () -> Void

    var body: some View {
        switch metric {
        case let .trainingDays(days):
            Section {
                Stepper(value: Binding(get: { days }, set: { onChange(.trainingDays(days: $0)) }),
                        in: WeeklyGoal.trainingDaysRange) {
                    Text("\(PolishPlural.days(days)) w tygodniu")
                }
            } footer: {
                Text("Liczy się każdy dzień z przynajmniej jednym zapisanym treningiem. Dni odpoczynku wybierasz sam.")
            }

        case let .plannedWorkouts(target):
            Section {
                Toggle("Wszystkie zaplanowane", isOn: Binding(
                    get: { target == .allScheduled },
                    set: { onChange(.plannedWorkouts(target: $0 ? .allScheduled : .count(workouts: 3))) }
                ))
                if case let .count(workouts) = target {
                    Stepper(value: Binding(get: { workouts }, set: { onChange(.plannedWorkouts(target: .count(workouts: $0))) }),
                            in: WeeklyGoal.plannedWorkoutsRange) {
                        Text("\(PolishPlural.workouts(workouts)) w tygodniu")
                    }
                }
            } footer: {
                Text(target == .allScheduled
                     ? "Cel to wszystkie treningi zaplanowane na dany tydzień. Trening przesunięty na inny dzień tego tygodnia też się liczy."
                     : "Liczą się treningi rozpoczęte z planu, w dowolne dni.")
            }

        case let .exerciseVolume(exerciseID, measurement, amount):
            Section {
                Button(action: onPickExercise) {
                    // The chevron shows the row opens the exercise picker.
                    HStack {
                        LabeledContent("Ćwiczenie", value: WeeklyGoalFormat.exerciseName(exerciseID))
                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(Color.textPrimary)

                WeeklyGoalAmountField(
                    amount: amount,
                    measurement: measurement,
                    onChange: { onChange(.exerciseVolume(exerciseID: exerciseID, measurement: measurement, amount: $0)) }
                )
            } footer: {
                Text(measurement == .seconds
                     ? "Suma sekund w tygodniu, np. 3 minuty L-situ."
                     : "Suma powtórzeń w tygodniu, np. 75 podciągnięć.")
            }
        }
    }
}

// MARK: - WeeklyGoalAmountField
/// A typed amount with a stepper: steps of 5 reps or 10 seconds.
private struct WeeklyGoalAmountField: View {
    let amount: Int
    let measurement: ExerciseMeasurement
    let onChange: (Int) -> Void

    private var step: Int { measurement == .seconds ? 10 : 5 }
    private var unit: String {
        measurement == .seconds
            ? String(localized: "s", comment: "Unit: seconds")
            : String(localized: "powt.", comment: "Unit: repetitions, abbreviated")
    }

    var body: some View {
        Stepper {
            HStack {
                TextField("Ilość", value: Binding(get: { amount }, set: { onChange(clamped($0)) }), format: .number)
                    .keyboardType(.numberPad)
                    .monospacedDigit()
                    .fixedSize()
                Text(unit)
                    .foregroundStyle(Color.textSecondary)
            }
        } onIncrement: {
            onChange(clamped(amount + step))
        } onDecrement: {
            onChange(clamped(amount - step))
        }
        .accessibilityValue(measurement == .seconds ? PolishPlural.seconds(amount) : PolishPlural.reps(amount))
    }

    private func clamped(_ value: Int) -> Int {
        min(max(value, WeeklyGoal.volumeRange.lowerBound), WeeklyGoal.volumeRange.upperBound)
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    let viewModel = AppEnvironment.previewEmpty.makeWeeklyGoalEditorViewModel()
    let _: Void = viewModel.load()
    let goalID = viewModel.addGoal(.exerciseVolume)
    NavigationStack {
        if let goalID {
            WeeklyGoalDetailView(viewModel: viewModel, goalID: goalID)
        }
    }
    .preferredColorScheme(.dark)
}
#endif
