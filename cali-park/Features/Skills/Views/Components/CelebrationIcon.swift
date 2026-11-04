import SwiftUI

// MARK: - CelebrationIcon
/// The celebration's icon, with a spring pulse each time the trigger changes;
/// still under Reduce Motion.
struct CelebrationIcon: View {
    let symbolName: String
    /// The trigger the pulse has played for; a new value replays it.
    let playedTrigger: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            ExerciseIconView(symbolName: symbolName, size: .detail)
        } else {
            PhaseAnimator([0.85, 1.1, 1.0], trigger: playedTrigger) { scale in
                ExerciseIconView(symbolName: symbolName, size: .detail)
                    .scaleEffect(scale)
            } animation: { _ in
                .spring(response: 0.45, dampingFraction: 0.7)
            }
        }
    }
}
