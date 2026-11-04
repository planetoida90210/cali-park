import SwiftUI

// MARK: - WorkoutPlansView
/// "Plany treningowe": the list of saved workout plans. Tap a plan to edit it,
/// "+" to create one, swipe to delete. "Gotowe programy" creates plans from a
/// ready-made program and then opens the first one in the editor. Pushed from
/// the Exercises tab and from Home.
struct WorkoutPlansView: View {
    @State private var viewModel: WorkoutPlansViewModel
    /// The "Czas na Fundamenty" card.
    @State private var graduation: ProgramGraduationViewModel
    @State private var editorRoute: PlanEditorRoute?
    @State private var showingPrograms = false
    /// A plan just created from a program, opened in the editor once the
    /// program sheet has closed.
    @State private var planCreatedFromProgram: WorkoutPlan?

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: environment.makeWorkoutPlansViewModel())
        _graduation = State(initialValue: environment.makeProgramGraduationViewModel())
    }

    var body: some View {
        Group {
            if viewModel.plans.isEmpty {
                WorkoutPlansEmptyState(onCreate: { editorRoute = .new },
                                       onBrowsePrograms: { showingPrograms = true })
            } else {
                WorkoutPlanList(viewModel: viewModel,
                                graduation: graduation,
                                onMoveOnToFundamentals: { Task { await moveOnToFundamentals() } },
                                onBrowsePrograms: { showingPrograms = true },
                                onEdit: { editorRoute = .edit($0) })
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Plany treningowe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorRoute = .new
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accent)
                }
                .accessibilityLabel("Nowy plan")
            }
        }
        .sheet(isPresented: $showingPrograms, onDismiss: openCreatedPlan) {
            ProgramBrowserView(environment: environment) { plans in
                planCreatedFromProgram = plans.first
                viewModel.reload()
                showingPrograms = false
            }
        }
        .sheet(item: $editorRoute) { route in
            PlanEditorView(viewModel: environment.makePlanEditorViewModel(plan: route.plan,
                                                                          isJustCreated: route.isJustCreated)) {
                viewModel.reload()
            }
        }
        .onAppear {
            viewModel.reload()
            graduation.reload()
        }
        .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
        .errorAlert($graduation.errorMessage)
    }

    /// "Przejdź na Fundamenty": replaces the plan, then opens the new one in
    /// the editor. It is a normal saved plan, so "Anuluj" keeps it.
    private func moveOnToFundamentals() async {
        let created = await graduation.moveOn()
        viewModel.reload()
        if let created { editorRoute = .edit(created) }
    }

    /// Opens the plan created from a program in the editor.
    private func openCreatedPlan() {
        guard let plan = planCreatedFromProgram else { return }
        planCreatedFromProgram = nil
        editorRoute = .created(plan)
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    NavigationStack {
        WorkoutPlansView(environment: .previewPlanToday)
    }
    .preferredColorScheme(.dark)
}
#endif
