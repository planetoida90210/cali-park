import SwiftUI

// MARK: - WorkoutHistoryView
/// "Ostatnie treningi": every logged entry, newest first, with
/// swipe-to-delete. Saved SetPad entries land here — that is the
/// confirmation that a save worked.
struct WorkoutHistoryView: View {
    @State private var viewModel: WorkoutHistoryViewModel

    init(viewModel: WorkoutHistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.entries.isEmpty {
                WorkoutHistoryEmptyState()
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                WorkoutHistoryRow(
                                    entry: entry,
                                    exercise: viewModel.exercise(for: entry),
                                    showsDate: !section.isSession
                                )
                                .listRowBackground(Color.componentBackground)
                                .listRowSeparatorTint(Color.divider)
                            }
                            .onDelete { offsets in
                                // Resolve entries up front — deleting shifts indices.
                                let doomed = offsets.map { section.entries[$0] }
                                for entry in doomed {
                                    viewModel.delete(entry)
                                }
                            }
                        } header: {
                            if section.isSession {
                                WorkoutSessionHeader(section: section)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Ostatnie treningi")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.reload() }
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

// MARK: - WorkoutSessionHeader
/// Header for a grouped quick-workout session: when it happened plus a summary.
private struct WorkoutSessionHeader: View {
    let section: WorkoutHistorySection

    var body: some View {
        HStack {
            Text(section.date, format: .dateTime.day().month().hour().minute())

            Spacer()

            Text("\(PolishPlural.exercises(section.entries.count)) · \(PolishPlural.reps(section.totalReps))")
        }
        .font(.bodySmall)
        .foregroundStyle(Color.textSecondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trening, \(PolishPlural.exercises(section.entries.count)), \(PolishPlural.reps(section.totalReps))")
    }
}

// MARK: - WorkoutHistoryRow
private struct WorkoutHistoryRow: View {
    let entry: WorkoutLogEntry
    let exercise: Exercise?
    /// Standalone rows show their own date; rows inside a session get it from
    /// the section header instead.
    var showsDate = true

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(
                symbolName: exercise?.symbolName ?? "figure.strengthtraining.functional",
                size: .row
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise?.name ?? "Ćwiczenie")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(entry.sets.map { String($0.reps) }.joined(separator: " + "))
                    .font(.bodySmall)
                    .monospacedDigit()
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if showsDate {
                    Text(entry.date, format: .dateTime.day().month())
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Text(PolishPlural.reps(entry.totalReps))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - WorkoutHistoryEmptyState
private struct WorkoutHistoryEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(Color.accent.opacity(0.8))

            Text("Brak treningów")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Otwórz ćwiczenie i zaloguj pierwszą serię.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        WorkoutHistoryView(
            viewModel: WorkoutHistoryViewModel(
                store: InMemoryWorkoutLogStore(initial: [
                    WorkoutLogEntry(
                        exerciseID: ExerciseCatalog.pullUpsID,
                        sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 8)]
                    )
                ])
            )
        )
    }
    .preferredColorScheme(.dark)
}
