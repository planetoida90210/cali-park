import SwiftUI

// MARK: - SetPadSheetView
/// Single-exercise set logger: type reps, `+` commits a set (habit: 6+6+6+8+6),
/// "Zapisz" persists one entry through `WorkoutLogViewModel`. Presented as a
/// medium-detent sheet from the exercise detail screen. The keypad itself lives
/// in the reusable `SetPadEntryView`.
struct SetPadSheetView: View {
    @State private var viewModel: WorkoutLogViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WorkoutLogViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SetPadEntryView(
            exercise: viewModel.exercise,
            input: $viewModel.input,
            cancel: SetPadEntryView.Cancel(hasUnsavedChanges: viewModel.hasUnsavedChanges) { dismiss() },
            onSave: { Task { await viewModel.save() } }
        )
        .disabled(viewModel.didSave || viewModel.isSaving)
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .presentationContentHeight()
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave { dismiss() }
        }
        .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
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
                    journal: TrainingJournal(store: InMemoryWorkoutLogStore())
                )
            )
        }
        .preferredColorScheme(.dark)
}
