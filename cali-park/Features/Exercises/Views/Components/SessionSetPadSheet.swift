import SwiftUI

// MARK: - SessionSetPadSheet
/// SetPad tuned for a session: logs sets for one exercise and hands them back
/// to the session (no persistence here — the session saves everything at once).
/// Seeds the keypad with `initialSets` when confirming a prefilled plan item.
struct SessionSetPadSheet: View {
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
