import SwiftUI

// MARK: - WorkoutSessionContentList
/// A saved workout's list: its totals, every exercise with its sets, and
/// "Usuń trening", which asks first (`onDelete` opens the confirmation).
struct WorkoutSessionContentList: View {
    let session: WorkoutSession
    let exercise: (WorkoutLogEntry) -> Exercise?
    let onDelete: () -> Void

    var body: some View {
        List {
            Section {
                WorkoutSessionSummaryHeader(session: session)
                    .listRowBackground(Color.componentBackground)
            }

            Section("Ćwiczenia") {
                ForEach(session.entries) { entry in
                    WorkoutSessionExerciseRow(entry: entry, exercise: exercise(entry))
                        .listRowBackground(Color.componentBackground)
                        .listRowSeparatorTint(Color.divider)
                }
            }

            Section {
                Button("Usuń trening", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
                .listRowBackground(Color.componentBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}
