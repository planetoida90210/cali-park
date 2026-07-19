import SwiftUI

// MARK: - HeroProgressionHintView
/// A subtle one-line nudge toward the athlete's next progression rung, shown on
/// the hero's rest-day and free-training states. The copy is built upstream by
/// `ProgressionFormat.hintLine(_:)`; this view only styles it.
struct HeroProgressionHintView: View {
    let hint: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text(hint)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Postęp: \(hint)")
    }
}
