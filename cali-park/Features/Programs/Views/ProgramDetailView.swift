import SwiftUI

// MARK: - ProgramDetailView
/// One ready-made program: who it is for, how often, what a session looks
/// like on the athlete's current rungs, how to progress, and the credit line.
/// "Utwórz plan" saves the plans and hands them to `onCreated`.
struct ProgramDetailView: View {
    @State private var viewModel: ProgramDetailViewModel
    let onCreated: ([WorkoutPlan]) -> Void

    init(viewModel: ProgramDetailViewModel, onCreated: @escaping ([WorkoutPlan]) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCreated = onCreated
    }

    var body: some View {
        List {
            ProgramHeaderSection(program: viewModel.program, schedule: viewModel.scheduleSummary)

            if viewModel.showsFirstPullUpHint {
                ProgramFirstPullUpHintSection()
            }

            ForEach(viewModel.previewPlans) { plan in
                ProgramSessionPreviewSection(plan: plan, viewModel: viewModel)
            }

            ProgramHowToTrainSection(program: viewModel.program)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(viewModel.program.name)
        .navigationBarTitleDisplayMode(.inline)
        // The ladder state is read here, not when the view model is built.
        .task { viewModel.reload() }
        .safeAreaInset(edge: .bottom) {
            Button(viewModel.isCreating ? "Tworzę plan…" : "Utwórz plan") {
                Task { await viewModel.requestCreate() }
            }
            .buttonStyle(.accent)
            .disabled(!viewModel.canCreate)
            .accessibilityIdentifier("programDetail.create")
            .padding()
            .background(Color.appBackground)
        }
        .onChange(of: viewModel.createdPlans) { _, plans in
            if let plans { onCreated(plans) }
        }
        .alert("Masz już plan z tego programu", isPresented: $viewModel.asksToCreateAnother) {
            Button("Anuluj", role: .cancel) {}
            Button("Utwórz drugi") {
                Task { await viewModel.create() }
            }
        } message: {
            Text("Utworzyć drugi?")
        }
        .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    let environment = AppEnvironment.seeded(placement: SkillPlacement(declaredRungByPath: [.pullUp: 3]))
    NavigationStack {
        ProgramDetailView(
            viewModel: environment.makeProgramDetailViewModel(program: ProgramCatalog.fundamentals),
            onCreated: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
#endif
