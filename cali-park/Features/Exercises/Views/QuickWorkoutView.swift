import SwiftUI

// MARK: - QuickWorkoutView
/// "Szybki trening": build a workout from any exercises, then save it as one
/// session. Add an exercise → log its sets on the SetPad → it joins the list →
/// repeat → "Zakończ" persists everything at once and pushes the summary, whose
/// "Gotowe" closes the sheet and lands on the Start tab.
struct QuickWorkoutView: View {
    @State private var viewModel: QuickWorkoutViewModel
    @State private var activeSheet: ActiveSheet?
    /// The saved workout, set after "Zakończ" to push its summary.
    @State private var summarySessionID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(TabRouter.self) private var router: TabRouter?

    init(viewModel: QuickWorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    QuickWorkoutEmptyState { activeSheet = .picker }
                } else {
                    sessionList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Szybki trening")
            .navigationBarTitleDisplayMode(.inline)
            // The empty state has its own "Dodaj ćwiczenie" button, so the
            // bottom bar only appears once the workout has an exercise.
            .safeAreaInset(edge: .bottom) {
                if !viewModel.isEmpty { bottomBar }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DiscardDraftButton(
                        hasUnsavedChanges: viewModel.hasUnsavedChanges,
                        title: "Odrzucić trening?",
                        message: "Dodane ćwiczenia i serie nie zostaną zapisane.",
                        onDiscard: { dismiss() }
                    )
                    .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zakończ") { viewModel.finish() }
                        .font(.buttonMedium)
                        .foregroundStyle(viewModel.canFinish ? Color.accent : Color.textSecondary)
                        .disabled(!viewModel.canFinish)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .picker:
                    ExercisePickerSheet { exercise in
                        activeSheet = .setPad(exercise)
                    }
                case .setPad(let exercise):
                    SessionSetPadSheet(exercise: exercise, initialSets: []) { sets in
                        viewModel.addExercise(exercise, sets: sets)
                        activeSheet = nil
                    }
                case .editItem(let item):
                    SessionSetPadSheet(exercise: item.exercise, initialSets: item.sets) { sets in
                        viewModel.updateSets(itemID: item.id, sets: sets)
                        activeSheet = nil
                    }
                }
            }
            .onChange(of: viewModel.didFinish) { _, didFinish in
                if didFinish {
                    summarySessionID = viewModel.savedSessionID
                }
            }
            .navigationDestination(item: $summarySessionID) { _ in
                WorkoutSessionDetailView(viewModel: viewModel.makeSummaryViewModel(), onDone: returnToStart)
            }
            .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
                Button("Rozumiem", role: .cancel) {}
            } message: {
                Text("Spróbuj ponownie.")
            }
        }
        // The sheet stays up on the summary after "Zakończ", so a conquered
        // rung celebrates here.
        .rewardOverlay()
        // A swipe must not drop an unsaved workout; "Anuluj" asks first. Once
        // saved, the summary's "Gotowe" is the way out.
        .interactiveDismissDisabled(viewModel.didFinish || viewModel.hasUnsavedChanges)
    }

    /// Closes the sheet on the Start tab, whichever tab the workout began on.
    private func returnToStart() {
        router?.selection = .home
        dismiss()
    }

    // MARK: Session list
    private var sessionList: some View {
        List {
            Section {
                ForEach(viewModel.items) { item in
                    Button {
                        activeSheet = .editItem(item)
                    } label: {
                        QuickWorkoutItemRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.componentBackground)
                    .listRowSeparatorTint(Color.divider)
                }
                .onDelete { offsets in
                    let doomed = offsets.map { viewModel.items[$0] }
                    for item in doomed { viewModel.remove(item) }
                }
            } footer: {
                Text("\(PolishPlural.exercises(viewModel.exerciseCount)) · \(PolishPlural.sets(viewModel.totalSets))")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: Bottom bar
    private var bottomBar: some View {
        Button {
            activeSheet = .picker
        } label: {
            Label("Dodaj ćwiczenie", systemImage: "plus")
                .font(.buttonLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.componentBackground)
                .foregroundStyle(Color.textPrimary)
                .clipShape(.rect(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // Bridges the optional `errorMessage` to a Bool binding for `.alert`.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - ActiveSheet
/// One binding for the whole picker → SetPad chain, so only one sub-sheet is
/// ever presented at a time.
private enum ActiveSheet: Identifiable {
    case picker
    case setPad(Exercise)
    case editItem(QuickWorkoutViewModel.DraftItem)

    var id: String {
        switch self {
        case .picker: "picker"
        case .setPad(let exercise): "add-\(exercise.id.uuidString)"
        case .editItem(let item): "edit-\(item.id.uuidString)"
        }
    }
}

// MARK: - SessionSetPadSheet
/// SetPad tuned for a session: logs sets for one exercise and hands them back
/// to the session (no persistence here — the session saves everything at once).
/// Seeds the keypad with `initialSets` when confirming a prefilled plan item.
private struct SessionSetPadSheet: View {
    let exercise: Exercise
    let initialSets: [LoggedSet]
    let onSave: ([LoggedSet]) -> Void

    /// What the keypad opened with; any difference is unsaved typing.
    private let initialInput: SetPadInput
    @State private var input: SetPadInput
    @Environment(\.dismiss) private var dismiss

    init(exercise: Exercise, initialSets: [LoggedSet], onSave: @escaping ([LoggedSet]) -> Void) {
        self.exercise = exercise
        self.initialSets = initialSets
        self.onSave = onSave
        let initialInput = SetPadInput(
            committedSets: initialSets.map { $0.padValue(for: exercise.measurement) }
        )
        self.initialInput = initialInput
        _input = State(initialValue: initialInput)
    }

    private var hasUnsavedChanges: Bool { input != initialInput }

    var body: some View {
        SetPadEntryView(
            exercise: exercise,
            input: $input,
            saveTitle: "Dodaj do treningu",
            cancel: SetPadEntryView.Cancel(hasUnsavedChanges: hasUnsavedChanges) { dismiss() }
        ) {
            onSave(input.loggedSets(for: exercise.measurement))
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .presentationContentHeight()
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
    }
}

// MARK: - QuickWorkoutItemRow
private struct QuickWorkoutItemRow: View {
    let item: QuickWorkoutViewModel.DraftItem

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: item.exercise.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.exercise.name)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                if item.isPending {
                    Text("Dotknij, aby dodać serie")
                        .font(.bodySmall)
                        .foregroundStyle(Color.accent)
                } else {
                    Text(MeasureFormat.breakdown(of: item.sets))
                        .font(.bodySmall)
                        .monospacedDigit()
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            if item.isPending {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.accent)
            } else {
                Text(MeasureFormat.total(of: item.sets))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(item.isPending ? "Dotknij, aby dodać serie" : "Dotknij, aby edytować serie")
    }
}

// MARK: - QuickWorkoutEmptyState
private struct QuickWorkoutEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundStyle(Color.accent)

            Text("Zbuduj trening")
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            Text("Dodaj dowolne ćwiczenia i zapisz je jako jeden trening.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onAdd) {
                Label("Dodaj ćwiczenie", systemImage: "plus")
                    .font(.buttonMedium)
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            QuickWorkoutView(
                viewModel: QuickWorkoutViewModel(journal: TrainingJournal(store: InMemoryWorkoutLogStore()))
            )
            .preferredColorScheme(.dark)
        }
}
