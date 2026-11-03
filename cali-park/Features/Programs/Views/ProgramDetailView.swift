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
                Section {
                    NavigationLink(value: ProgramID.firstPullUp) {
                        Label("Nie robisz jeszcze pełnego podciągnięcia? Zacznij od programu Pierwsze podciągnięcie.",
                              systemImage: "lightbulb")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .listRowBackground(Color.componentBackground)
                }
            }

            ForEach(viewModel.previewPlans) { plan in
                Section {
                    ForEach(plan.exercises) { planned in
                        ProgramItemRow(exercise: viewModel.exercise(for: planned),
                                       target: viewModel.targetSummary(for: planned, in: plan))
                            .listRowBackground(Color.componentBackground)
                    }
                } header: {
                    Text("Trening na Twoich szczeblach")
                } footer: {
                    Text("Gdy awansujesz na drabinie, plan przejdzie na nowy szczebel sam.")
                }
            }

            Section {
                ForEach(viewModel.program.details, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                        .listRowBackground(Color.componentBackground)
                }
            } header: {
                Text("Jak trenować")
            } footer: {
                Text(viewModel.program.creditLine)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(viewModel.program.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await viewModel.create() }
            } label: {
                Text(viewModel.isCreating ? "Tworzę plan…" : "Utwórz plan")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canCreate)
            .opacity(viewModel.canCreate ? 1 : 0.5)
            .padding()
            .background(Color.appBackground)
        }
        .onChange(of: viewModel.createdPlans) { _, plans in
            if let plans { onCreated(plans) }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("Rozumiem", role: .cancel) {}
        } message: {
            Text("Spróbuj ponownie.")
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

// MARK: - ProgramHeaderSection
private struct ProgramHeaderSection: View {
    let program: TrainingProgram
    let schedule: String

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(program.tagline)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                Text(program.audience)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.componentBackground)

            LabeledContent("Jak często", value: program.frequency)
                .listRowBackground(Color.componentBackground)
            LabeledContent("Czas treningu", value: program.sessionLength)
                .listRowBackground(Color.componentBackground)
            LabeledContent("Dni na start", value: schedule)
                .listRowBackground(Color.componentBackground)
        } footer: {
            Text("Dni zmienisz potem w edytorze planu.")
        }
        .foregroundStyle(Color.textPrimary)
    }
}

// MARK: - ProgramItemRow
private struct ProgramItemRow: View {
    let exercise: Exercise?
    let target: String?

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise?.symbolName ?? "figure.strengthtraining.functional", size: .row)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? "Ćwiczenie")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                if let target {
                    Text(target)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

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
