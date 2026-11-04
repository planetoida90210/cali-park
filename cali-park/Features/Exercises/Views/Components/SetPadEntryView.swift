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
    var saveTitle: LocalizedStringKey = "Zapisz"
    /// Adds an "Anuluj" to the header that asks before dropping typed sets.
    /// `nil` hides it (the caller offers its own way out).
    var cancel: Cancel? = nil
    let onSave: () -> Void

    /// How the header's "Anuluj" behaves.
    struct Cancel {
        let hasUnsavedChanges: Bool
        let onCancel: () -> Void
    }

    @AppStorage(DefaultsKey.hasSeenSetPadHint.rawValue) private var hasSeenSetPadHint = false

    var body: some View {
        VStack(spacing: 16) {
            SetPadHeader(exercise: exercise) {
                if let cancel {
                    DiscardDraftButton(
                        hasUnsavedChanges: cancel.hasUnsavedChanges,
                        title: "Odrzucić serie?",
                        message: "Wpisane serie nie zostaną zapisane.",
                        onDiscard: cancel.onCancel
                    )
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                }
            }

            SetPadDisplay(
                input: input,
                measurement: exercise.measurement,
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
                    .clipShape(.rect(cornerRadius: AppRadius.medium))
            }
            .disabled(!input.canSave)
            .accessibilityIdentifier("setPad.save")
        }
        .sensoryFeedback(.impact(weight: .light), trigger: input.committedSets.count) { old, new in
            new > old
        }
        .onChange(of: input.committedSets.count) { old, new in
            if new > old { hasSeenSetPadHint = true }
        }
    }
}

// MARK: - Preview
#Preview {
    SetPadEntryView(exercise: ExerciseCatalog.all[0], input: .constant(SetPadInput())) {}
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
