import SwiftUI

// MARK: - StreakDayCell
/// One day of the month grid: an accent fill when trained, a ring on today.
struct StreakDayCell: View {
    let dayNumber: Int
    let isTrained: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isTrained ? Color.accent.opacity(0.3) : Color.clear)

            if isToday {
                Circle()
                    .stroke(Color.accent, lineWidth: 1)
            }

            Text("\(dayNumber)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
        }
        .scaledIconFrame(28, relativeTo: .caption)
        .accessibilityLabel(isTrained ? String(localized: "\(dayNumber), trening zaliczony") : "\(dayNumber)")
    }
}
