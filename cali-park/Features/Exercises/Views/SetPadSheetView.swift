import SwiftUI

// MARK: - SetPadSheetView
/// Calculator-style set logger: type reps, `+` commits a set (habit: 6+6+6+8+6),
/// "Zapisz" persists the entry. Presented as a medium-detent sheet from the
/// exercise detail screen.
struct SetPadSheetView: View {
    @State private var viewModel: WorkoutLogViewModel
    @AppStorage("hasSeenSetPadHint") private var hasSeenSetPadHint = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WorkoutLogViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            SetPadHeader(exercise: viewModel.exercise)

            SetPadDisplay(
                input: viewModel.input,
                showsHint: !hasSeenSetPadHint,
                onClear: { viewModel.input.clear() }
            )

            SetPadKeypad(input: $viewModel.input)

            Button {
                viewModel.save()
            } label: {
                Text("Zapisz")
                    .font(.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.input.canSave ? Color.accent : Color.componentBackground)
                    .foregroundStyle(viewModel.input.canSave ? Color.black : Color.textSecondary)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(!viewModel.input.canSave)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.input.committedSets.count) { old, new in
            new > old
        }
        .onChange(of: viewModel.input.committedSets.count) { old, new in
            if new > old { hasSeenSetPadHint = true }
        }
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave { dismiss() }
        }
        .alert("Błąd", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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

// MARK: - SetPadHeader
private struct SetPadHeader: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .row)

            Text(exercise.name)
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
    }
}

// MARK: - SetPadDisplay
private struct SetPadDisplay: View {
    let input: SetPadInput
    let showsHint: Bool
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                if !input.setsForSaving.isEmpty {
                    Button("Wyczyść", action: onClear)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text(input.displayText)
                    .font(.system(.largeTitle, design: .rounded, weight: .light))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: input.displayText)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Text(summaryText)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: summaryText)
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Serie: \(input.displayText). \(summaryText)")
    }

    private var summaryText: String {
        if showsHint && input.setsForSaving.isEmpty {
            return "Każdy + to nowa seria"
        }
        let sets = input.setsForSaving.count
        return "\(PolishPlural.sets(sets)) · \(PolishPlural.reps(input.totalReps))"
    }
}

// MARK: - SetPadKeypad
private struct SetPadKeypad: View {
    @Binding var input: SetPadInput

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                digitKey(1); digitKey(2); digitKey(3)
            }
            GridRow {
                digitKey(4); digitKey(5); digitKey(6)
            }
            GridRow {
                digitKey(7); digitKey(8); digitKey(9)
            }
            GridRow {
                SetPadKey(label: "Usuń", isEnabled: canDelete) {
                    input.deleteBackward()
                } content: {
                    Image(systemName: "delete.left")
                }

                digitKey(0)

                SetPadKey(label: "Dodaj serię", isAccent: true, isEnabled: input.canCommit) {
                    input.commitSet()
                } content: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var canDelete: Bool {
        !input.currentEntry.isEmpty || !input.committedSets.isEmpty
    }

    private func digitKey(_ digit: Int) -> some View {
        SetPadKey(label: "\(digit)", isEnabled: true) {
            input.appendDigit(digit)
        } content: {
            Text("\(digit)")
        }
    }
}

// MARK: - SetPadKey
private struct SetPadKey<Content: View>: View {
    let label: String
    var isAccent = false
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .font(.title3)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(isAccent ? Color.accent : Color.componentBackground)
                .foregroundStyle(isAccent ? Color.black : Color.textPrimary)
                .clipShape(.rect(cornerRadius: 12))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SetPadSheetView(
                viewModel: WorkoutLogViewModel(
                    exercise: ExerciseCatalog.all[0],
                    store: InMemoryWorkoutLogStore()
                )
            )
        }
        .preferredColorScheme(.dark)
}
