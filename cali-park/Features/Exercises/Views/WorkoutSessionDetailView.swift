import SwiftUI

// MARK: - WorkoutSessionDetailView
/// One saved workout: when it happened, its totals, every exercise with its
/// sets, and a way to delete it. Pushed from Home and the history list; also
/// shown as the summary right after "Zakończ" in a quick workout, where
/// `onDone` adds "Gotowe" and replaces the back button.
struct WorkoutSessionDetailView: View {
    @State private var viewModel: WorkoutSessionDetailViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    /// Set when shown as the post-finish summary.
    private let onDone: (() -> Void)?

    init(viewModel: WorkoutSessionDetailViewModel, onDone: (() -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.onDone = onDone
    }

    var body: some View {
        Group {
            if let session = viewModel.session {
                WorkoutSessionContentList(session: session,
                                          exercise: { viewModel.exercise(for: $0) },
                                          onDelete: { isConfirmingDelete = true })
            } else {
                ContentUnavailableView(
                    "Trening usunięty",
                    systemImage: "trash",
                    description: Text("Tego treningu nie ma już w historii.")
                )
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(onDone == nil ? "Trening" : "Podsumowanie")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(onDone != nil)
        .safeAreaInset(edge: .bottom) {
            if let onDone {
                Button("Gotowe", action: onDone)
                    .buttonStyle(.accent)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .confirmationDialog("Usunąć ten trening?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Usuń trening", role: .destructive) { Task { await viewModel.delete() } }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Tej operacji nie można cofnąć.")
        }
        .onChange(of: viewModel.didDelete) { _, didDelete in
            guard didDelete else { return }
            if let onDone {
                onDone()
            } else {
                dismiss()
            }
        }
        .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
        .onAppear { viewModel.reload() }
    }
}

#if DEBUG
// MARK: - Preview
#Preview("Szczegóły") {
    let session = UUID()
    NavigationStack {
        WorkoutSessionDetailView(
            viewModel: WorkoutSessionDetailViewModel(
                sessionID: session,
                journal: TrainingJournal(store: InMemoryWorkoutLogStore(initial: [
                    WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)], sessionID: session),
                    WorkoutLogEntry(exerciseID: ExerciseCatalog.plankID, sets: [LoggedSet(reps: 1, durationSeconds: 45)], sessionID: session)
                ]))
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Podsumowanie") {
    let session = UUID()
    NavigationStack {
        WorkoutSessionDetailView(
            viewModel: WorkoutSessionDetailViewModel(
                sessionID: session,
                journal: TrainingJournal(store: InMemoryWorkoutLogStore(initial: [
                    WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 15), LoggedSet(reps: 12)], sessionID: session)
                ]))
            ),
            onDone: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
