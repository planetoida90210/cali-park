import SwiftUI

// MARK: - CelebrationOverlayView
/// The full-screen moment when a rung or a level is conquered: one icon, one
/// headline, the XP it earned, and a way forward. Shown one advance at a time
/// (the view model queues the rest), with success haptics on appear.
///
/// Restraint over fireworks: a single clear message, not a wall of text. The
/// entrance pulse is skipped under Reduce Motion, and every way to dismiss is a
/// real `Button`, so VoiceOver and Switch Control reach it.
///
/// Also used for a met weekly goal: pass a ready `CelebrationPresentation` and
/// a stable `trigger` for the haptic and the entrance pulse.
struct CelebrationOverlayView: View {
    let presentation: CelebrationPresentation
    /// Identifies the celebrated moment; a new value replays haptics and pulse.
    let trigger: String
    /// Whether another advance follows, so the button reads "Dalej" vs "Świetnie".
    let hasNext: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(presentation: CelebrationPresentation,
         trigger: String,
         hasNext: Bool,
         onDismiss: @escaping () -> Void) {
        self.presentation = presentation
        self.trigger = trigger
        self.hasNext = hasNext
        self.onDismiss = onDismiss
    }

    /// A rung or level advance from the Skills reward loop.
    init(event: CelebrationEvent, hasNext: Bool, onDismiss: @escaping () -> Void) {
        self.init(presentation: .resolving(event), trigger: event.id, hasNext: hasNext, onDismiss: onDismiss)
    }

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
        // Full screen over the app: VoiceOver stays inside until it is dismissed.
        .accessibilityAddTraits(.isModal)
        .sensoryFeedback(.success, trigger: trigger)
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
            PhaseAnimator([0.85, 1.1, 1.0], trigger: trigger) { scale in
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
                event: .rungConquered(RungReference(pathID: .pullUp, stepID: ExerciseCatalog.pullUpsID)),
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
