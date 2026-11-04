import SwiftUI

// MARK: - HeroPlayIcon
/// A gentle pulse to draw the eye to the primary action: a few beats
/// each time the hero appears, then still. Static when the user prefers
/// reduced motion.
struct HeroPlayIcon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Bumped on appear to play the pulse once more.
    @State private var pulseTrigger = 0

    var body: some View {
        let icon = Image(systemName: "play.fill").accessibilityHidden(true)
        if reduceMotion {
            icon
        } else {
            icon.phaseAnimator(PulsePhases.beats(HeroPlanTodayView.pulseBeats), trigger: pulseTrigger) { view, pulsing in
                view.scaleEffect(pulsing ? 1.12 : 1)
            } animation: { _ in
                .easeInOut(duration: 0.45)
            }
            .onAppear { pulseTrigger += 1 }
        }
    }
}
