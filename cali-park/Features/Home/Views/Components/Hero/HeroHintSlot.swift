import SwiftUI

// MARK: - HeroHintSlot
/// The hero's one-line hint on rest and free-training days. While the
/// Planner's "Czas na Fundamenty" card is waiting, the line leads to the
/// plans list, where that card is; otherwise it is the progression nudge.
/// Shows nothing when neither applies.
struct HeroHintSlot: View {
    /// Whether "Czas na Fundamenty" is waiting in the Planner.
    let showsGraduation: Bool
    /// The progression nudge, or `nil` when no rung is partway done.
    let progressionHint: String?

    var body: some View {
        if showsGraduation {
            HeroGraduationHintLink()
        } else if let progressionHint {
            HeroProgressionHintView(hint: progressionHint)
        }
    }
}

// MARK: - HeroGraduationHintLink
/// "Czas na Fundamenty", one tap from the plans list with its card. Pushes
/// `HomeRoute.plans` on Home's navigation stack.
struct HeroGraduationHintLink: View {
    var body: some View {
        NavigationLink(value: HomeRoute.plans) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)

                Text("Czas na Fundamenty — zobacz w Planach")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otwiera plany treningowe")
        .accessibilityIdentifier("home.hero.graduationHint")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        VStack(alignment: .leading, spacing: 16) {
            HeroHintSlot(showsGraduation: true, progressionHint: "Jeszcze 2 powtórzenia do 3 × 8")
            HeroHintSlot(showsGraduation: false, progressionHint: "Jeszcze 2 powtórzenia do 3 × 8")
            HeroHintSlot(showsGraduation: true, progressionHint: nil)
                .dynamicTypeSize(.accessibility3)
        }
        .padding()
        .background(Color.componentBackground)
    }
    .preferredColorScheme(.dark)
}
