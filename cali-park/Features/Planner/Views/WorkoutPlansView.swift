import SwiftUI

// MARK: - WorkoutPlansView
/// "Plany treningowe": the list of saved workout plans. Tap a plan to edit it,
/// "+" to create one, swipe to delete. Pushed from the Exercises tab.
struct WorkoutPlansView: View {
    @State private var viewModel: WorkoutPlansViewModel
    @State private var editorRoute: PlanEditorRoute?

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: environment.makeWorkoutPlansViewModel())
    }

    var body: some View {
        Group {
            if viewModel.plans.isEmpty {
                WorkoutPlansEmptyState { editorRoute = .new }
            } else {
                planList
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
        .sheet(item: $editorRoute) { route in
            PlanEditorView(viewModel: environment.makePlanEditorViewModel(plan: route.plan)) {
                viewModel.reload()
            }
        }
        .onAppear { viewModel.reload() }
        .alert("Błąd", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Plan list
    private var planList: some View {
        List {
            ForEach(viewModel.plans) { plan in
                Button {
                    editorRoute = .edit(plan)
                } label: {
                    WorkoutPlanRow(plan: plan, summary: viewModel.scheduleSummary(for: plan))
                }
                .listRowBackground(Color.componentBackground)
                .listRowSeparatorTint(Color.divider)
            }
            .onDelete { offsets in
                offsets.map { viewModel.plans[$0] }.forEach(viewModel.delete)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // Bridges the optional `errorMessage` to a Bool binding for `.alert`.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - PlanEditorRoute
/// Presents the editor for a new plan or an existing one via `sheet(item:)`,
/// so the sheet opens only once its backing plan is decided.
private enum PlanEditorRoute: Identifiable {
    case new
    case edit(WorkoutPlan)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let plan): plan.id.uuidString
        }
    }

    var plan: WorkoutPlan? {
        switch self {
        case .new: nil
        case .edit(let plan): plan
        }
    }
}

// MARK: - WorkoutPlanRow
private struct WorkoutPlanRow: View {
    let plan: WorkoutPlan
    let summary: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(summary)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Text(PolishPlural.exercises(plan.exerciseCount))
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - WorkoutPlansEmptyState
private struct WorkoutPlansEmptyState: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(Color.accent)

            Text("Zaplanuj trening")
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            Text("Zbuduj plan z ulubionych ćwiczeń i ustaw, jak często chcesz go trenować.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onCreate) {
                Label("Nowy plan", systemImage: "plus")
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
    NavigationStack {
        WorkoutPlansView(environment: .preview)
    }
    .preferredColorScheme(.dark)
}
