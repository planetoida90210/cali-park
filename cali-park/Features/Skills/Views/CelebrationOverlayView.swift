import SwiftUI

// MARK: - CelebrationOverlayView
/// The full-screen moment when a rung or a level is conquered: one icon, one
/// headline, the XP it earned, and a way forward. Shown one overlay at a time
/// (`RewardCenter` queues the rest; rungs conquered together share one card),
/// with success haptics on appear, including the first one.
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

    /// The trigger the haptic and the pulse have played for. It starts `nil`
    /// and takes `trigger` on appear, so the first (or only) celebration plays
    /// them too: both modifiers fire only when their trigger changes (A-9).
    @State private var playedTrigger: String?

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

    private var card: some View {
        CelebrationCard(presentation: presentation,
                        hasNext: hasNext,
                        playedTrigger: playedTrigger,
                        onDismiss: onDismiss)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
    }

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(0.8).ignoresSafeArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Zamknij")
            .accessibilityIdentifier("celebration.dismiss")

            // Centered while it fits; a card listing several rungs at large
            // text sizes scrolls instead of running off the screen.
            ViewThatFits(in: .vertical) {
                card
                ScrollView {
                    card
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        // Full screen over the app: VoiceOver stays inside until it is dismissed.
        .accessibilityAddTraits(.isModal)
        .sensoryFeedback(.success, trigger: playedTrigger)
        .onChange(of: trigger, initial: true) { _, newTrigger in
            playedTrigger = newTrigger
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

#Preview("Kilka szczebli") {
    Color.appBackground.ignoresSafeArea()
        .overlay {
            CelebrationOverlayView(
                presentation: .resolving(QueuedCelebration.rungs((0...5).compactMap { RungReference(pathID: .pullUp, rungIndex: $0) })),
                trigger: "preview",
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
