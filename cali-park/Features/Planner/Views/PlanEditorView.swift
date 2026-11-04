import SwiftUI

// MARK: - PlanEditorView
/// Create or edit a workout plan: name it, add exercises, pick how often it
/// repeats, and optionally set a reminder. "Zapisz" is enabled only once the
/// plan is complete.
struct PlanEditorView: View {
    @State private var viewModel: PlanEditorViewModel
    @State private var showingPicker = false
    @Environment(\.dismiss) private var dismiss

    /// Called after a successful save, or after "Anuluj" deleted a plan just
    /// created from a program, so the presenter can refresh its list.
    var onSave: () -> Void = {}

    init(viewModel: PlanEditorViewModel, onSave: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                PlanNameSection(name: $viewModel.name)
                if let origin = viewModel.programOrigin {
                    PlanOriginSection(line: origin.line, credit: origin.credit)
                }
                PlanExercisesSection(viewModel: viewModel) { showingPicker = true }
                PlanScheduleSection(viewModel: viewModel)
                PlanReminderSection(viewModel: viewModel)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Plan treningu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DiscardDraftButton(
                        hasUnsavedChanges: viewModel.hasUnsavedChanges,
                        title: "Odrzucić zmiany w planie?",
                        message: "Wprowadzone zmiany nie zostaną zapisane.",
                        onDiscard: {
                            Task {
                                guard await viewModel.cancel() else { return }
                                if viewModel.isJustCreated { onSave() }
                                dismiss()
                            }
                        }
                    )
                    .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zapisz") {
                        Task { await viewModel.save() }
                    }
                    .font(.buttonMedium)
                    .foregroundStyle(canTapSave ? Color.accent : Color.textSecondary)
                    .disabled(!canTapSave)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerSheet { exercise in
                    viewModel.addExercise(exercise)
                    showingPicker = false
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                guard saved else { return }
                onSave()
                // A reminder warning shows first; its button closes the editor.
                if viewModel.errorMessage == nil { dismiss() }
            }
            .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
                Button("Rozumiem", role: .cancel) {
                    if viewModel.didSave { dismiss() }
                }
            } message: {
                Text(viewModel.didSave ? "Sprawdź ustawienia powiadomień." : "Spróbuj ponownie.")
            }
            .task { await viewModel.refreshNotificationPermission() }
        }
        // A swipe must not drop unsaved edits; "Anuluj" asks first. A plan
        // just created from a program closes only through "Anuluj" (which
        // deletes it) or "Zapisz", so a swipe can't leave it half-decided.
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges || viewModel.isJustCreated)
    }

    private var canTapSave: Bool { viewModel.canSave && !viewModel.isSaving }

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
                PlanExerciseRow(exercise: viewModel.exercise(for: planned),
                                target: viewModel.targetSummary(for: planned),
                                ladder: viewModel.ladderName(for: planned))
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

// MARK: - PlanOriginSection
/// Which program the plan came from, with the program's credit line.
private struct PlanOriginSection: View {
    let line: String
    let credit: String

    var body: some View {
        Section {
            Label(line, systemImage: "list.bullet.clipboard")
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        } footer: {
            Text(credit.keptTogether)
        }
    }
}

// MARK: - PlanExerciseRow
private struct PlanExerciseRow: View {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(WorkoutScheduleFormatter.summary(viewModel.schedule))
                if let problem = viewModel.scheduleProblem {
                    Label(problem, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusOrange)
                }
            }
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
            DatePicker("Data", selection: $viewModel.onceDate, in: viewModel.earliestOnceDate..., displayedComponents: .date)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        }
    }
}

// MARK: - PlanReminderSection
/// The reminder toggle and its time. Turning it on may show the system
/// permission prompt; when notifications are off, a short note links to the
/// app's notification settings.
private struct PlanReminderSection: View {
    @Bindable var viewModel: PlanEditorViewModel

    var body: some View {
        Section {
            Toggle("Przypomnienie", isOn: reminderBinding)
                .tint(Color.accent)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)

            if viewModel.reminderEnabled {
                DatePicker("Godzina", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    .foregroundStyle(Color.textPrimary)
                    .listRowBackground(Color.componentBackground)
            }
        } footer: {
            if viewModel.showsNotificationsDeniedHint {
                NotificationsDeniedHint()
            } else if viewModel.reminderEnabled {
                Text("Przypomnimy Ci o treningu w zaplanowane dni.")
            }
        }
    }

    /// The toggle shows the new value at once; the view model may turn it
    /// back off when notifications are denied.
    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { viewModel.reminderEnabled },
            set: { enabled in Task { await viewModel.setReminderEnabled(enabled) } }
        )
    }
}

// MARK: - NotificationsDeniedHint
private struct NotificationsDeniedHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Powiadomienia są wyłączone. Włącz je w Ustawieniach, żeby dostawać przypomnienia.")
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                Link("Otwórz Ustawienia", destination: url)
                    .foregroundStyle(Color.accent)
            }
        }
    }
}

// MARK: - WeekdaySelector
/// Row of weekday toggles in the user's locale order (Monday-first in Poland).
/// Multiple days can be active — that is the weekly schedule's `Set<Weekday>`.
/// At accessibility text sizes the seven days don't fit one row, so they wrap
/// into rows of four.
private struct WeekdaySelector: View {
    let selected: Set<Weekday>
    let onToggle: (Weekday) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: typeSize.isAccessibilitySize ? 4 : 7)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Weekday.ordered()) { day in
                let isOn = selected.contains(day)
                Button {
                    onToggle(day)
                } label: {
                    Text(day.shortName)
                        .font(.buttonSmall)
                        .frame(maxWidth: .infinity, minHeight: 40)
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
                viewModel: AppEnvironment.seeded().makePlanEditorViewModel()
            )
            .preferredColorScheme(.dark)
        }
}
