import SwiftUI

// MARK: - SetPadEntryView
/// Reusable calculator-style set entry: exercise header, the running
/// `6 + 6 + 8` display, the keypad and the save button. Persistence is the
/// caller's job — `onSave` fires when the button is tapped, so the same view
/// drives both the single-exercise sheet (persists immediately) and a quick
/// workout session (accumulates in memory).
struct SetPadEntryView: View {
    let exercise: Exercise
    @Binding var input: SetPadInput
    var saveTitle = "Zapisz"
    let onSave: () -> Void

    @AppStorage("hasSeenSetPadHint") private var hasSeenSetPadHint = false

    var body: some View {
        VStack(spacing: 16) {
            SetPadHeader(exercise: exercise)

            SetPadDisplay(
                input: input,
                showsHint: !hasSeenSetPadHint,
                onClear: { input.clear() }
            )

            SetPadKeypad(input: $input)

            Button(action: onSave) {
                Text(saveTitle)
                    .font(.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(input.canSave ? Color.accent : Color.componentBackground)
                    .foregroundStyle(input.canSave ? Color.black : Color.textSecondary)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(!input.canSave)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: input.committedSets.count) { old, new in
            new > old
        }
        .onChange(of: input.committedSets.count) { old, new in
            if new > old { hasSeenSetPadHint = true }
        }
    }
}

// MARK: - SetPadHeader
struct SetPadHeader: View {
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
    SetPadEntryView(exercise: ExerciseCatalog.all[0], input: .constant(SetPadInput())) {}
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
