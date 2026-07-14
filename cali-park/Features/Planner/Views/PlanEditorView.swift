import SwiftUI

// MARK: - PlanEditorView
/// Create or edit a workout plan: name it, add exercises, and pick how often it
/// repeats. "Zapisz" is enabled only once the plan is complete.
struct PlanEditorView: View {
    @State private var viewModel: PlanEditorViewModel
    @State private var showingPicker = false
    @Environment(\.dismiss) private var dismiss

    /// Called after a successful save so the presenter can refresh its list.
    var onSave: () -> Void = {}

    init(viewModel: PlanEditorViewModel, onSave: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                PlanNameSection(name: $viewModel.name)
                PlanExercisesSection(viewModel: viewModel) { showingPicker = true }
                PlanScheduleSection(viewModel: viewModel)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Plan treningu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zapisz") { viewModel.save() }
                        .font(.buttonMedium)
                        .foregroundStyle(viewModel.canSave ? Color.accent : Color.textSecondary)
                        .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerSheet { exercise in
                    viewModel.addExercise(exercise)
                    showingPicker = false
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    onSave()
                    dismiss()
                }
            }
            .alert("Błąd", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // Bridges the optional `errorMessage` to a Bool binding for `.alert`.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - PlanNameSection
private struct PlanNameSection: View {
    @Binding var name: String

    var body: some View {
        Section {
            TextField("Nazwa planu", text: $name)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        } header: {
            Text("Nazwa")
        }
    }
}

// MARK: - PlanExercisesSection
private struct PlanExercisesSection: View {
    let viewModel: PlanEditorViewModel
    let onAdd: () -> Void

    var body: some View {
        Section {
            ForEach(viewModel.exercises) { planned in
                PlanExerciseRow(exercise: viewModel.exercise(for: planned))
                    .listRowBackground(Color.componentBackground)
            }
            .onDelete { viewModel.remove(atOffsets: $0) }

            Button(action: onAdd) {
                Label("Dodaj ćwiczenie", systemImage: "plus")
                    .foregroundStyle(Color.accent)
            }
            .listRowBackground(Color.componentBackground)
        } header: {
            Text("Ćwiczenia")
        } footer: {
            if viewModel.exercises.isEmpty {
                Text("Dodaj co najmniej jedno ćwiczenie.")
            }
        }
    }
}

// MARK: - PlanExerciseRow
private struct PlanExerciseRow: View {
    let exercise: Exercise?

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(
                symbolName: exercise?.symbolName ?? "figure.strengthtraining.functional",
                size: .row
            )

            Text(exercise?.name ?? "Ćwiczenie")
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PlanScheduleSection
private struct PlanScheduleSection: View {
    @Bindable var viewModel: PlanEditorViewModel

    var body: some View {
        Section {
            Picker("Powtarzalność", selection: $viewModel.scheduleMode) {
                ForEach(PlanEditorViewModel.ScheduleMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.componentBackground)

            scheduleDetail
        } header: {
            Text("Harmonogram")
        } footer: {
            Text(WorkoutScheduleFormatter.summary(viewModel.schedule))
        }
    }

    @ViewBuilder
    private var scheduleDetail: some View {
        switch viewModel.scheduleMode {
        case .weekly:
            WeekdaySelector(selected: viewModel.selectedWeekdays) { viewModel.toggle($0) }
                .listRowBackground(Color.componentBackground)
        case .everyNDays:
            Stepper(value: $viewModel.interval, in: 1...30) {
                Text(viewModel.interval == 1 ? "Codziennie" : "Co \(PolishPlural.days(viewModel.interval))")
                    .foregroundStyle(Color.textPrimary)
            }
            .listRowBackground(Color.componentBackground)
        case .once:
            DatePicker("Data", selection: $viewModel.onceDate, displayedComponents: .date)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        }
    }
}

// MARK: - WeekdaySelector
/// Row of weekday toggles in the user's locale order (Monday-first in Poland).
/// Multiple days can be active — that is the weekly schedule's `Set<Weekday>`.
private struct WeekdaySelector: View {
    let selected: Set<Weekday>
    let onToggle: (Weekday) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Weekday.ordered()) { day in
                let isOn = selected.contains(day)
                Button {
                    onToggle(day)
                } label: {
                    Text(day.shortName)
                        .font(.buttonSmall)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isOn ? Color.accent : Color.appBackground)
                        .foregroundStyle(isOn ? Color.black : Color.textPrimary)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.displayName)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PlanEditorView(
                viewModel: PlanEditorViewModel(plan: nil, store: InMemoryWorkoutPlanStore())
            )
            .preferredColorScheme(.dark)
        }
}
