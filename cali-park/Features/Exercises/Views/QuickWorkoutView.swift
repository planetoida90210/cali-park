import SwiftUI

// MARK: - QuickWorkoutView
/// "Szybki trening": build a workout from any exercises, then save it as one
/// session. Add an exercise → log its sets on the SetPad → it joins the list →
/// repeat → "Zakończ trening" persists everything at once.
struct QuickWorkoutView: View {
    @State private var viewModel: QuickWorkoutViewModel
    @State private var activeSheet: ActiveSheet?
    @Environment(\.dismiss) private var dismiss

    /// Called after the session is saved, so the presenter can refresh.
    var onFinish: () -> Void = {}

    init(viewModel: QuickWorkoutViewModel, onFinish: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
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
            .safeAreaInset(edge: .bottom) { bottomBar }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
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
                    SessionSetPadSheet(exercise: exercise) { sets in
                        viewModel.addExercise(exercise, sets: sets)
                        activeSheet = nil
                    }
                }
            }
            .onChange(of: viewModel.didFinish) { _, didFinish in
                if didFinish {
                    onFinish()
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

    // MARK: Session list
    private var sessionList: some View {
        List {
            Section {
                ForEach(viewModel.items) { item in
                    QuickWorkoutItemRow(item: item)
                        .listRowBackground(Color.componentBackground)
                        .listRowSeparatorTint(Color.divider)
                }
                .onDelete { offsets in
                    let doomed = offsets.map { viewModel.items[$0] }
                    for item in doomed { viewModel.remove(item) }
                }
            } footer: {
                Text("\(viewModel.exerciseCount) · \(PolishPlural.sets(viewModel.totalSets))")
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

    var id: String {
        switch self {
        case .picker: "picker"
        case .setPad(let exercise): exercise.id.uuidString
        }
    }
}

// MARK: - SessionSetPadSheet
/// SetPad tuned for a session: logs sets for one exercise and hands them back
/// to the session (no persistence here — the session saves everything at once).
private struct SessionSetPadSheet: View {
    let exercise: Exercise
    let onAdd: ([LoggedSet]) -> Void

    @State private var input = SetPadInput()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SetPadEntryView(
            exercise: exercise,
            input: $input,
            saveTitle: "Dodaj do treningu"
        ) {
            onAdd(input.setsForSaving.map { LoggedSet(reps: $0) })
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .presentationDetents([.medium])
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

                Text(item.sets.map { String($0.reps) }.joined(separator: " + "))
                    .font(.bodySmall)
                    .monospacedDigit()
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Text(PolishPlural.reps(item.totalReps))
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
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
                viewModel: QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
            )
            .preferredColorScheme(.dark)
        }
}
