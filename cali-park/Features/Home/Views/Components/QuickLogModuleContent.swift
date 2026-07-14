import SwiftUI

// MARK: - Szybki trening Module
/// Home entry into a quick workout: one button starts a session of any
/// exercises, and the latest entry is shown as a glanceable preview.
struct QuickLogModuleContent: View {
    let dashboard: HomeDashboardViewModel

    @State private var showingQuickWorkout = false

    var body: some View {
        VStack(spacing: 12) {
            Button {
                showingQuickWorkout = true
            } label: {
                Label("Szybki trening", systemImage: "bolt.fill")
                    .font(.buttonMedium)
                    .lineLimit(1)
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
                        Text("Brak zapisów — zaloguj pierwszy trening.")
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
        .sheet(isPresented: $showingQuickWorkout) {
            QuickWorkoutView(
                viewModel: dashboard.makeQuickWorkoutViewModel(),
                onFinish: { dashboard.reload() }
            )
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
