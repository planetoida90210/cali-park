import SwiftUI

// MARK: - WeeklyGoalRing
/// A progress ring for one weekly goal: accent while running, a checkmark once
/// met, grey during a pause. Size it with `.frame`.
struct WeeklyGoalRing: View {
    let progress: Double
    let isMet: Bool
    var isDimmed: Bool = false
    var lineWidth: CGFloat = 5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }
    private var tint: Color { isDimmed ? Color.textSecondary : Color.accent }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appBackground, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: clamped)

            if isMet {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(tint)
            } else {
                Text(clamped, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 16) {
        WeeklyGoalRing(progress: 0, isMet: false).frame(width: 44, height: 44)
        WeeklyGoalRing(progress: 0.66, isMet: false).frame(width: 44, height: 44)
        WeeklyGoalRing(progress: 1, isMet: true).frame(width: 44, height: 44)
        WeeklyGoalRing(progress: 0.3, isMet: false, isDimmed: true).frame(width: 44, height: 44)
    }
    .padding()
    .background(Color.componentBackground)
    .preferredColorScheme(.dark)
}
