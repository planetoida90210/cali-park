import SwiftUI

// MARK: - HeroFirstRunView
/// A fresh start: no plans, empty journal. The hero is an invitation — plan the
/// first workout, or just start one now. Both CTAs do real work.
struct HeroFirstRunView: View {
    let name: String
    var now: Date = .now
    let onPlanWorkout: () -> Void
    let onQuickWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(name: name, now: now)

                Text("Zacznij swoją serię")
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)

                Text("Zaplanuj pierwszy trening albo od razu zaloguj serię.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: 8) {
                Button(action: onPlanWorkout) {
                    Text("Zaplanuj trening")
                }
                .buttonStyle(HeroPrimaryButtonStyle())

                Button(action: onQuickWorkout) {
                    Text("Szybki trening")
                }
                .buttonStyle(HeroSecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Preview
#Preview("Pierwszy start") {
    HeroFirstRunView(
        name: "Michał",
        onPlanWorkout: {},
        onQuickWorkout: {}
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
