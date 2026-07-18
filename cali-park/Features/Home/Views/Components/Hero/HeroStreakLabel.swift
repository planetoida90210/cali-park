import SwiftUI

// MARK: - HeroStreakLabel
/// A compact streak line (flame + day count) shared by the hero states that
/// keep the streak visible while nothing is scheduled for right now.
struct HeroStreakLabel: View {
    let streak: WorkoutStreak

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak.current > 0 ? Color.orange : Color.textSecondary)
                .accessibilityHidden(true)

            Text("Streak: \(PolishPlural.days(streak.current))")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Aktualny streak: \(PolishPlural.days(streak.current))")
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HeroStreakLabel(streak: WorkoutStreak(current: 0, longest: 4, trainedDays: []))
        HeroStreakLabel(streak: WorkoutStreak(current: 5, longest: 9, trainedDays: []))
    }
    .padding()
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
