import SwiftUI

// MARK: - HeroWeeklyRingView
/// The weekly pull-up goal, demoted to a secondary line inside the hero
/// (completed / rest / free mode). The ring and the count never disappear —
/// they just step back here from the old always-on hero card. A "dumb" view:
/// progress and reps are passed in; the owner reads them from the view model.
struct HeroWeeklyRingView: View {
    let weeklyReps: Int
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        HStack(spacing: 12) {
            ring

            Text("\(PolishPlural.pullUps(weeklyReps)) w tym tygodniu")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cel tygodnia: \(Int(clampedProgress * 100)) procent, \(PolishPlural.pullUps(weeklyReps))")
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.componentBackground, lineWidth: 5)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(Color.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: clampedProgress)

            Text(clampedProgress, format: .percent.precision(.fractionLength(0)))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.accent)
                .contentTransition(.numericText())
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HeroWeeklyRingView(weeklyReps: 0, progress: 0)
        HeroWeeklyRingView(weeklyReps: 32, progress: 0.45)
        HeroWeeklyRingView(weeklyReps: 120, progress: 1)
    }
    .padding()
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
