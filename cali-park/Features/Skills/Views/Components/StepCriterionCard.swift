import SwiftUI

// MARK: - StepCriterionCard
/// The rung's target ("Cel") with the athlete's logged best, a progress bar
/// and the criterion's source; read by VoiceOver as one element.
struct StepCriterionCard: View {
    let step: ProgressionStep
    let progress: RungProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cel")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            Text(MeasureFormat.criterion(for: step))
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)

            if let note = step.criterionNote {
                Text(note)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }

            if step.unilateralSide != nil {
                Text("Wpisz wynik słabszej strony.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            if let best = MeasureFormat.best(progress) {
                Text("Twoje najlepsze: \(best)")
                    .font(.bodyMedium)
                    .foregroundStyle(progress.isMet ? Color.accent : Color.textSecondary)
            } else {
                Text("Zaloguj serię, aby zmierzyć postęp.")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }

            ProgressView(value: progress.fractionComplete)
                .tint(Color.accent)
                .padding(.top, 4)

            Text(step.criterionSource.sourceLine.keptTogether)
                .font(.bodySmall)
                .foregroundStyle(Color.textTertiary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityCriterion)
        .accessibilityValue(accessibilityProgress)
    }

    private var accessibilityCriterion: String {
        var parts = [String(localized: "Cel: \(MeasureFormat.spokenCriterion(for: step))")]
        if let note = step.criterionNote { parts.append(note) }
        if step.unilateralSide != nil { parts.append(String(localized: "Wpisz wynik słabszej strony")) }
        parts.append(String(localized: "Źródło: \(step.criterionSource.explanation)"))
        return parts.joined(separator: ". ")
    }

    private var accessibilityProgress: String {
        guard let best = MeasureFormat.best(progress) else {
            return String(localized: "Brak zapisów")
        }
        return progress.isMet ? String(localized: "Zaliczone, \(best)") : String(localized: "Twoje najlepsze: \(best)")
    }
}
