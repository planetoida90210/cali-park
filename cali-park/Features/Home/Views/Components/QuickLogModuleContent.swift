import SwiftUI

// MARK: - Quick Log Module
/// One-tap set logging from Home: opens the SetPad with the most recently
/// logged exercise (pull-ups for a fresh journal) and shows the latest entry.
struct QuickLogModuleContent: View {
    let dashboard: HomeDashboardViewModel

    /// Payload-driven sheet — set only when logging starts.
    @State private var loggingExercise: Exercise?

    var body: some View {
        VStack(spacing: 12) {
            Button {
                loggingExercise = dashboard.quickLogExercise
            } label: {
                HStack {
                    Image(systemName: "plus")

                    Text("Dodaj serię — \(dashboard.quickLogExercise.name)")
                        .font(.buttonMedium)
                        .lineLimit(1)
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accent)
                .clipShape(.rect(cornerRadius: 8))
            }

            // Ostatni zapis
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ostatni zapis")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)

                    if let entry = dashboard.latestEntry {
                        Text(latestEntryText(entry))
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textPrimary)

                        Text(entry.date, format: .dateTime.day().month().hour().minute())
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        Text("Brak zapisów — zaloguj pierwszą serię.")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.glassBackground)
            .clipShape(.rect(cornerRadius: 8))
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.glassBackground.blur(radius: 30))
        .clipShape(.rect(cornerRadius: 12))
        .sheet(item: $loggingExercise, onDismiss: { dashboard.reload() }) { exercise in
            SetPadSheetView(viewModel: dashboard.makeWorkoutLogViewModel(exercise: exercise))
        }
    }

    /// "Podciągnięcia · 6 + 6 + 8".
    private func latestEntryText(_ entry: WorkoutLogEntry) -> String {
        let name = dashboard.exercise(for: entry)?.name ?? "Ćwiczenie"
        let sets = entry.sets.map { String($0.reps) }.joined(separator: " + ")
        return "\(name) · \(sets)"
    }
}

// MARK: - Preview
#Preview {
    QuickLogModuleContent(dashboard: AppEnvironment.preview.makeHomeDashboardViewModel())
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
