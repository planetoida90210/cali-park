import SwiftUI

// MARK: - HeroWeeklyGoalView
/// The weekly goal inside the hero (completed / rest / free mode): a ring with
/// the primary goal's progress, the goal and its count, and the week streak.
/// A long press, or the VoiceOver action, opens the goal editor.
struct HeroWeeklyGoalView: View {
    let snapshot: WeeklyGoalSnapshot
    let onEdit: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var primary: WeeklyGoalProgress { snapshot.week.primary }
    private var isPaused: Bool { snapshot.activePause != nil }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                // The goal gets the full width under the ring and the streak.
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ring
                        Spacer(minLength: 0)
                        HeroWeekStreakBadge(weeks: snapshot.streak)
                    }
                    goalText(lineLimit: nil)
                }
            } else {
                HStack(spacing: 12) {
                    ring
                    goalText(lineLimit: 2)
                    Spacer(minLength: 0)
                    HeroWeekStreakBadge(weeks: snapshot.streak)
                }
            }
        }
        .contentShape(.rect)
        .onLongPressGesture(minimumDuration: 0.4, perform: onEdit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Przytrzymaj, aby zmienić cel")
        .accessibilityAction(named: "Zmień cel tygodniowy", onEdit)
    }

    private var ring: some View {
        WeeklyGoalRing(progress: primary.fraction, isMet: primary.isMet, isDimmed: isPaused)
            .scaledIconFrame(44, relativeTo: .subheadline)
    }

    private func goalText(lineLimit: Int?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(WeeklyGoalFormat.title(primary.goal.metric))
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(lineLimit)

            Text(detailLine)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(lineLimit)
                .contentTransition(.numericText())
        }
    }

    /// "2 / 3 dni", or the pause / verdict note when one applies.
    private var detailLine: String {
        if let pause = snapshot.activePause { return WeeklyGoalFormat.pauseLine(pause) }
        let progress = WeeklyGoalFormat.progress(primary)
        guard let status = WeeklyGoalFormat.status(snapshot.week) else { return progress }
        return "\(progress) · \(status)"
    }

    private var accessibilityText: String {
        var parts = [String(localized: "Cel tygodniowy: \(WeeklyGoalFormat.spokenTitle(primary.goal.metric))")]
        if let pause = snapshot.activePause {
            parts.append(WeeklyGoalFormat.pauseLine(pause))
        } else {
            parts.append(WeeklyGoalFormat.spokenProgress(primary))
            if let status = WeeklyGoalFormat.status(snapshot.week) { parts.append(status) }
        }
        parts.append(WeeklyGoalFormat.streak(snapshot.streak))
        return parts.joined(separator: ", ")
    }
}

// MARK: - HeroWeekStreakBadge
/// Flame, the week streak count and "seria tygodni". VoiceOver reads the
/// parent's combined label instead.
private struct HeroWeekStreakBadge: View {
    let weeks: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(weeks > 0 ? Color.streak : Color.textSecondary)
                Text(weeks, format: .number)
                    .font(.appTitle3)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
            }
            Text("seria tygodni")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HeroWeeklyGoalView(snapshot: WeeklyGoalPreview.running, onEdit: {})
        HeroWeeklyGoalView(snapshot: WeeklyGoalPreview.met, onEdit: {})
        HeroWeeklyGoalView(snapshot: WeeklyGoalPreview.paused, onEdit: {})
    }
    .padding()
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: AppRadius.medium))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
