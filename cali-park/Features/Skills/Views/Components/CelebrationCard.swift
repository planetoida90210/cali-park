import SwiftUI

// MARK: - CelebrationCard
/// The celebration's card: the icon, eyebrow, headline, optional subtitle and
/// XP note, and the button that moves on; read by VoiceOver as one element.
struct CelebrationCard: View {
    let presentation: CelebrationPresentation
    /// Whether another advance follows, so the button reads "Dalej" vs "Świetnie".
    let hasNext: Bool
    /// The trigger the entrance pulse has played for; a new value replays it.
    let playedTrigger: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            CelebrationIcon(symbolName: presentation.symbolName, playedTrigger: playedTrigger)

            VStack(spacing: 8) {
                Text(presentation.eyebrow)
                    .font(.bodySmall)
                    .tracking(1.5)
                    .foregroundStyle(Color.accent)

                Text(presentation.title)
                    .font(.appTitle)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle = presentation.subtitle {
                    Text(subtitle)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }

                if let xpNote = presentation.xpNote {
                    Text(xpNote)
                        .font(.buttonMedium)
                        .foregroundStyle(Color.accent)
                        .padding(.top, 4)
                }
            }

            Button(hasNext ? "Dalej" : "Świetnie", action: onDismiss)
                .buttonStyle(.accent)
        }
        .padding(24)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(presentation.accessibilityLabel)
    }
}
