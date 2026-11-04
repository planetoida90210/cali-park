import SwiftUI

// MARK: - HeroFirstRunView
/// A fresh start: no plans, empty journal. The hero is a short invitation; the
/// two permanent actions ("Szybki trening" / "Plany") live in the rail right
/// below, so it points there instead of repeating the same buttons.
struct HeroFirstRunView: View {
    /// The weekly goal row; `nil` hides it (the goal could not be read).
    var weeklyGoal: WeeklyGoalSnapshot? = nil
    /// Opens the goal editor (long press on the goal row).
    var onEditGoal: () -> Void = {}
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(now: now)

                Text("Zacznij swoją serię")
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)

                Text("Wybierz poniżej szybki trening albo ułóż swój pierwszy plan.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            if let weeklyGoal {
                Divider().overlay(Color.divider)

                HeroWeeklyGoalView(snapshot: weeklyGoal, onEdit: onEditGoal)
            }
        }
    }
}

// MARK: - Preview
#Preview("Pierwszy start") {
    HeroFirstRunView()
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
