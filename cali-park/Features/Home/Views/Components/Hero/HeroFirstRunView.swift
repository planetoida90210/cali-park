import SwiftUI

// MARK: - HeroFirstRunView
/// A fresh start: no plans, empty journal. The hero is a short invitation; the
/// two permanent actions ("Szybki trening" / "Plany") live in the rail right
/// below, so it points there instead of repeating the same buttons.
struct HeroFirstRunView: View {
    let name: String
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HeroHeaderView(name: name, now: now)

            Text("Zacznij swoją serię")
                .font(.title2)
                .foregroundStyle(Color.textPrimary)

            Text("Wybierz poniżej szybki trening albo ułóż swój pierwszy plan.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview("Pierwszy start") {
    HeroFirstRunView(name: "Michał")
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
