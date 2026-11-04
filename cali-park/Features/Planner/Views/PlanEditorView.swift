import SwiftUI

// MARK: - PlanEditorView
/// Create or edit a workout plan: name it, add exercises, pick how often it
/// repeats, and optionally set a reminder. "Zapisz" is enabled only once the
/// plan is complete.
struct PlanEditorView: View {
    @State private var viewModel: PlanEditorViewModel
    @State private var showingPicker = false
    @Environment(\.dismiss) private var dismiss

    /// Called after a successful save, or after "Anuluj" deleted a plan just
    /// created from a program, so the presenter can refresh its list.
    var onSave: () -> Void = {}

    init(viewModel: PlanEditorViewModel, onSave: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                PlanNameSection(name: $viewModel.name)
                if let origin = viewModel.programOrigin {
                    PlanOriginSection(line: origin.line, credit: origin.credit)
                }
                PlanExercisesSection(viewModel: viewModel) { showingPicker = true }
                PlanScheduleSection(viewModel: viewModel)
                PlanReminderSection(viewModel: viewModel)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Plan treningu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DiscardDraftButton(
                        hasUnsavedChanges: viewModel.hasUnsavedChanges,
                        title: "Odrzucić zmiany w planie?",
                        message: "Wprowadzone zmiany nie zostaną zapisane.",
                        onDiscard: {
                            Task {
                                guard await viewModel.cancel() else { return }
                                if viewModel.isJustCreated { onSave() }
                                dismiss()
                            }
                        }
                    )
                    .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zapisz") {
                        Task { await viewModel.save() }
                    }
                    .font(.buttonMedium)
                    .foregroundStyle(canTapSave ? Color.accent : Color.textSecondary)
                    .disabled(!canTapSave)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerSheet { exercise in
                    viewModel.addExercise(exercise)
                    showingPicker = false
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                guard saved else { return }
                onSave()
                // A reminder warning shows first; its button closes the editor.
                if viewModel.errorMessage == nil { dismiss() }
            }
            .errorAlert(
                $viewModel.errorMessage,
                hint: viewModel.didSave ? "Sprawdź ustawienia powiadomień." : "Spróbuj ponownie."
            ) {
                if viewModel.didSave { dismiss() }
            }
            .task { await viewModel.refreshNotificationPermission() }
        }
        // A swipe must not drop unsaved edits; "Anuluj" asks first. A plan
        // just created from a program closes only through "Anuluj" (which
        // deletes it) or "Zapisz", so a swipe can't leave it half-decided.
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges || viewModel.isJustCreated)
    }

    private var canTapSave: Bool { viewModel.canSave && !viewModel.isSaving }
}

#if DEBUG
// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PlanEditorView(
                viewModel: AppEnvironment.seeded().makePlanEditorViewModel()
            )
            .preferredColorScheme(.dark)
        }
}

#Preview("AX5") {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PlanEditorView(
                viewModel: AppEnvironment.seeded().makePlanEditorViewModel()
            )
            .dynamicTypeSize(.accessibility5)
            .preferredColorScheme(.dark)
        }
}
#endif
