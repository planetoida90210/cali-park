import SwiftUI

// MARK: - Ostatni trening Module
/// Glanceable preview of the most recent workout on Home; tapping it opens the
/// workout detail. The action to log lives in the primary action rail, so this
/// module never duplicates the "Szybki trening" button.
struct LastWorkoutModuleContent: View {
    let dashboard: HomeDashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            if let workout = dashboard.latestWorkout {
                NavigationLink(value: WorkoutSessionRoute(sessionID: workout.id)) {
                    LastWorkoutCard(
                        headline: HeroWorkoutSummary.headline(for: workout),
                        subtitle: subtitle(for: workout),
                        date: workout.date
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Pokaż szczegóły treningu")
            } else {
                HStack {
                    Text("Brak treningów. Zaloguj pierwszy.")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()
                }
                .padding(16)
                .background(Color.glassBackground)
                .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.glassBackground.blur(radius: 30))
        .clipShape(.rect(cornerRadius: 12))
    }

    /// For a session, the exercises it contained; otherwise nothing.
    private func subtitle(for workout: WorkoutSession) -> String? {
        guard workout.isSession else { return nil }
        return workout.entries
            .map { dashboard.exercise(for: $0)?.name ?? "Ćwiczenie" }
            .joined(separator: " · ")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LastWorkoutModuleContent(dashboard: AppEnvironment.previewCompletedToday.makeHomeDashboardViewModel())
            .padding()
            .background(Color.appBackground)
    }
    .preferredColorScheme(.dark)
}
