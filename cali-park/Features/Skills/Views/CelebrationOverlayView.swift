import SwiftUI

// MARK: - CelebrationOverlayView
/// The full-screen moment when a rung or a level is conquered: one icon, one
/// headline, the XP it earned, and a way forward. Shown one advance at a time
/// (the view model queues the rest), with success haptics on appear.
///
/// Restraint over fireworks: a single clear message, not a wall of text. The
/// entrance pulse is skipped under Reduce Motion, and every way to dismiss is a
/// real `Button`, so VoiceOver and Switch Control reach it.
struct CelebrationOverlayView: View {
    let event: CelebrationEvent
    /// Whether another advance follows, so the button reads "Dalej" vs "Świetnie".
    let hasNext: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var presentation: CelebrationPresentation { .resolving(event) }

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(0.8).ignoresSafeArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Zamknij")

            card
                .padding(.horizontal, 32)
        }
        .sensoryFeedback(.success, trigger: event)
    }

    // MARK: Card
    private var card: some View {
        VStack(spacing: 24) {
            icon

            VStack(spacing: 8) {
                Text(presentation.eyebrow)
                    .font(.bodySmall)
                    .tracking(1.5)
                    .foregroundStyle(Color.accent)

                Text(presentation.title)
                    .font(.title1)
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

            Button(action: onDismiss) {
                Text(hasNext ? "Dalej" : "Świetnie")
                    .font(.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accent)
                    .foregroundStyle(Color.black)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    // MARK: Icon
    @ViewBuilder
    private var icon: some View {
        if reduceMotion {
            ExerciseIconView(symbolName: presentation.symbolName, size: .detail)
        } else {
            PhaseAnimator([0.85, 1.1, 1.0], trigger: event) { scale in
                ExerciseIconView(symbolName: presentation.symbolName, size: .detail)
                    .scaleEffect(scale)
            } animation: { _ in
                .spring(response: 0.45, dampingFraction: 0.7)
            }
        }
    }
}

// MARK: - Preview
#Preview("Szczebel") {
    Color.appBackground.ignoresSafeArea()
        .overlay {
            CelebrationOverlayView(
                event: .rungConquered(RungReference(pathID: .pullUp, rungIndex: 4)),
                hasNext: true,
                onDismiss: {}
            )
        }
        .preferredColorScheme(.dark)
}

#Preview("Poziom") {
    Color.appBackground.ignoresSafeArea()
        .overlay {
            CelebrationOverlayView(
                event: .levelReached(3),
                hasNext: false,
                onDismiss: {}
            )
        }
        .preferredColorScheme(.dark)
}
