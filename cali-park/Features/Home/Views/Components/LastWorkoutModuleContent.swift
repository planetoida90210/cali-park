import SwiftUI

// MARK: - Ostatni trening Module
/// Glanceable preview of the most recent workout on Home. Read-only — the
/// action to log lives in the primary action rail, so this module never
/// duplicates the "Szybki trening" button.
struct LastWorkoutModuleContent: View {
    let dashboard: HomeDashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ostatni trening")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)

                    if let workout = dashboard.latestWorkout {
                        Text(headline(for: workout))
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textPrimary)

                        if let subtitle = subtitle(for: workout) {
                            Text(subtitle)
                                .font(.bodySmall)
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(1)
                        }

                        Text(workout.date, format: .dateTime.day().month().hour().minute())
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
    }

    /// Session: "3 ćwiczenia · 68 powtórzeń". Single: "Podciągnięcia · 6 + 6 + 8"
    /// (or "Front lever · 3 × 20 s" for a timed exercise).
    private func headline(for workout: HomeDashboardViewModel.LatestWorkout) -> String {
        if workout.isSession {
            return "\(PolishPlural.exercises(workout.entries.count)) · \(SetLogFormat.totals(reps: workout.totalReps, seconds: workout.totalSeconds))"
        }
        let entry = workout.entries[0]
        let name = dashboard.exercise(for: entry)?.name ?? "Ćwiczenie"
        return "\(name) · \(SetLogFormat.breakdown(of: entry.sets))"
    }

    /// For a session, the exercises it contained; otherwise nothing.
    private func subtitle(for workout: HomeDashboardViewModel.LatestWorkout) -> String? {
        guard workout.isSession else { return nil }
        return workout.entries
            .map { dashboard.exercise(for: $0)?.name ?? "Ćwiczenie" }
            .joined(separator: " · ")
    }
}

// MARK: - Preview
#Preview {
    LastWorkoutModuleContent(dashboard: AppEnvironment.preview.makeHomeDashboardViewModel())
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
