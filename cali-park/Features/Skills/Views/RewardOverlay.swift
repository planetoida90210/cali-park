import SwiftUI

// MARK: - RewardOverlay
/// Presents a `SkillPathsViewModel`'s reward loop — the celebration overlay and
/// the XP toast — over any Skills screen.
///
/// Both the paths grid and a path's ladder build their own view model, and
/// training happens on the ladder. Attaching the same overlay to both means a
/// conquered rung celebrates wherever the athlete happens to be, and the shared
/// progress store keeps it to exactly once.
struct RewardOverlay: ViewModifier {
    let viewModel: SkillPathsViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let amount = viewModel.xpToastAmount {
                    XPToastView(amount: amount)
                        .padding(.top, 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .task(id: amount) {
                            try? await Task.sleep(for: .seconds(2))
                            viewModel.clearXPToast()
                        }
                }
            }
            .overlay {
                if let event = viewModel.currentCelebration {
                    CelebrationOverlayView(
                        event: event,
                        hasNext: viewModel.hasQueuedCelebrations,
                        onDismiss: { viewModel.dismissCurrentCelebration() }
                    )
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.currentCelebration)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.xpToastAmount)
    }
}

extension View {
    /// Shows the reward loop (celebration overlay + XP toast) for a Skills view
    /// model on top of this view.
    func rewardOverlay(_ viewModel: SkillPathsViewModel) -> some View {
        modifier(RewardOverlay(viewModel: viewModel))
    }
}
