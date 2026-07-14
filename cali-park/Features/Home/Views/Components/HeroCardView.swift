import SwiftUI

struct HeroCardView: View {
    let name: String
    let weeklyReps: Int
    let progress: Double

    var body: some View {
        HStack(alignment: .top) {
            // Left content: Greeting + Weekly Reps
            VStack(alignment: .leading, spacing: 4) {
                Text("Siema, \(name)!")
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)

                Text("\(PolishPlural.pullUps(weeklyReps)) w tym tygodniu")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.accent)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Right content: Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.componentBackground.opacity(0.3), lineWidth: 6)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.degrees(270))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)

                // Percentage text
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.bodyMedium)
                    .foregroundStyle(Color.accent)
                    .contentTransition(.numericText())
            }
            .frame(width: 56, height: 56)
            .accessibilityLabel("Cel tygodnia: \(Int(progress * 100)) procent")
        }
        .padding(16)
        .background(Color.black)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    HeroCardView(
        name: "Michał",
        weeklyReps: 57,
        progress: 0.75
    )
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
