import SwiftUI

// MARK: - WeeklyGoalModule
/// The Home module id for "Cel tygodniowy". Stored in the module preferences,
/// so it must never change.
enum WeeklyGoalModule {
    static let id = "goal"
}

// MARK: - WeeklyGoalModuleContent
/// The "Cel tygodniowy" Home module: every goal with its progress this week,
/// the week streak, the pause, and a way into the editor.
struct WeeklyGoalModuleContent: View {
    /// `nil` when the goal could not be read.
    let snapshot: WeeklyGoalSnapshot?
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let snapshot {
                WeeklyGoalModuleHeader(snapshot: snapshot)

                ForEach(snapshot.week.goals) { progress in
                    WeeklyGoalProgressRow(
                        progress: progress,
                        isPrimary: progress.id == snapshot.week.primary.id,
                        isDimmed: snapshot.activePause != nil
                    )
                }
            } else {
                Text("Nie udało się odczytać celu tygodniowego.")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }

            Button("Zmień cele", systemImage: "slider.horizontal.3", action: onEdit)
                .font(.buttonMedium)
                .foregroundStyle(Color.accent)
                .disabled(snapshot == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - WeeklyGoalModuleHeader
/// Week streak plus the pause or the week's verdict.
private struct WeeklyGoalModuleHeader: View {
    let snapshot: WeeklyGoalSnapshot

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(snapshot.streak > 0 ? Color.orange : Color.textSecondary)
                .accessibilityHidden(true)

            Text(WeeklyGoalFormat.streak(snapshot.streak))
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Spacer(minLength: 8)

            if let note {
                Text(note)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var note: String? {
        if let pause = snapshot.activePause { return WeeklyGoalFormat.pauseLine(pause) }
        return WeeklyGoalFormat.status(snapshot.week)
    }
}

// MARK: - WeeklyGoalProgressRow
/// One goal: title, count and a progress bar; the primary goal is marked.
private struct WeeklyGoalProgressRow: View {
    let progress: WeeklyGoalProgress
    let isPrimary: Bool
    let isDimmed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if isPrimary {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                }

                Text(WeeklyGoalFormat.title(progress.goal.metric))
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                if progress.isMet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                }

                Text(WeeklyGoalFormat.progress(progress))
                    .font(.bodySmall)
                    .monospacedDigit()
                    .foregroundStyle(Color.textSecondary)
                    .contentTransition(.numericText())
            }

            ProgressView(value: progress.fraction)
                .tint(isDimmed ? Color.textSecondary : Color.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [WeeklyGoalFormat.spokenTitle(progress.goal.metric)]
        if isPrimary { parts.append("cel główny") }
        parts.append(WeeklyGoalFormat.spokenProgress(progress))
        if progress.isMet { parts.append("wykonany") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        WeeklyGoalModuleContent(snapshot: WeeklyGoalPreview.running, onEdit: {})
        WeeklyGoalModuleContent(snapshot: WeeklyGoalPreview.paused, onEdit: {})
        WeeklyGoalModuleContent(snapshot: nil, onEdit: {})
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
