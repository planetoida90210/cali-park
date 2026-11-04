import SwiftUI

// MARK: - RoundTrackerRow
/// The round counter of a pair or circuit: "Runda 2/3" with "Runda
/// zrobiona", then the rest countdown with "Pomiń". The rest clears itself
/// when it runs out.
struct RoundTrackerRow: View {
    let tracker: RoundTracker
    let onFinishRound: () -> Void
    let onEndRest: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(ProgramFormat.roundLabel(for: tracker))
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                if let rest = tracker.rest {
                    restCountdown(rest)
                } else if tracker.hasMetMinimum, !tracker.isFinished {
                    Text("Minimum zrobione, kolejne rundy są dla chętnych")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }

            if tracker.rest != nil {
                Button("Pomiń przerwę", action: onEndRest)
                    .font(.buttonMedium)
                    .foregroundStyle(Color.accent)
            } else if !tracker.isFinished {
                Button("Runda zrobiona", systemImage: "checkmark", action: onFinishRound)
                    .buttonStyle(.accent(.compact, fillsWidth: false))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .task(id: tracker.rest) {
            guard let rest = tracker.rest else { return }
            let remaining = rest.end.timeIntervalSinceNow
            if remaining > 0 {
                do {
                    try await Task.sleep(for: .seconds(remaining))
                } catch {
                    return
                }
            }
            onEndRest()
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: tracker.rest) { old, new in
            old != nil && new == nil
        }
    }

    private func restCountdown(_ rest: DateInterval) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .accessibilityHidden(true)
            Text("Przerwa")
            Text(timerInterval: rest.start...rest.end, countsDown: true)
                .monospacedDigit()
        }
        .font(.bodySmall)
        .foregroundStyle(Color.accent)
        .accessibilityElement(children: .combine)
    }
}
