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
                    QuickWorkoutSessionList(viewModel: viewModel) { activeSheet = .editItem($0) }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            // The empty state has its own "Dodaj ćwiczenie" button, so the
            // bottom bar only appears once the workout has an exercise.
            .safeAreaInset(edge: .bottom) {
                if !viewModel.isEmpty {
                    QuickWorkoutBottomBar { activeSheet = .picker }
                }
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
                    Button("Zakończ") { Task { await viewModel.finish() } }
                        .font(.buttonMedium)
                        .foregroundStyle(viewModel.canFinish ? Color.accent : Color.textSecondary)
                        .disabled(!viewModel.canFinish)
                        .accessibilityIdentifier("quickWorkout.finish")
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
            .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
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

#if DEBUG
// MARK: - Preview
#Preview("Fundamenty") {
    let plan = ProgramPrescriber.plans(for: ProgramCatalog.fundamentals, pathStates: [:])[0]
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            QuickWorkoutView(
                viewModel: QuickWorkoutViewModel(journal: TrainingJournal(store: InMemoryWorkoutLogStore()),
                                                 plan: plan, clock: { .now })
            )
            .preferredColorScheme(.dark)
        }
}

#Preview("Fundamenty AX5") {
    let plan = ProgramPrescriber.plans(for: ProgramCatalog.fundamentals, pathStates: [:])[0]
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            QuickWorkoutView(
                viewModel: QuickWorkoutViewModel(journal: TrainingJournal(store: InMemoryWorkoutLogStore()),
                                                 plan: plan, clock: { .now })
            )
            .dynamicTypeSize(.accessibility5)
            .preferredColorScheme(.dark)
        }
}

#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            QuickWorkoutView(
                viewModel: QuickWorkoutViewModel(journal: TrainingJournal(store: InMemoryWorkoutLogStore()), clock: { .now })
            )
            .preferredColorScheme(.dark)
        }
}
#endif
