import SwiftUI

// MARK: - RewardOverlay
/// Presents the app's `RewardCenter` — the celebration overlay and the XP
/// toast — on top of this view, read from the SwiftUI environment.
///
/// Mounted on the tab root and on the sheets that stay up after a save. While
/// several are on screen, only the most recently shown one presents, so a
/// reward never plays (or times out) hidden under a sheet, and the center
/// keeps it to exactly once.
struct RewardOverlay: ViewModifier {
    @Environment(RewardCenter.self) private var center: RewardCenter?
    @State private var presenterID = UUID()

    func body(content: Content) -> some View {
        if let center {
            content
                .modifier(RewardOverlayContent(center: center, isPresenting: center.isPresenting(presenterID)))
                .onAppear { center.register(presenter: presenterID) }
                .onDisappear { center.unregister(presenter: presenterID) }
        } else {
            content
        }
    }
}

// MARK: - RewardOverlayContent
private struct RewardOverlayContent: ViewModifier {
    let center: RewardCenter
    let isPresenting: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var toastAmount: Int? { isPresenting ? center.xpToastAmount : nil }
    private var celebration: RewardPresentation? { isPresenting ? center.current : nil }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let amount = toastAmount {
                    XPToastView(amount: amount)
                        .padding(.top, 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .task(id: amount) {
                            try? await Task.sleep(for: .seconds(2))
                            center.clearXPToast()
                        }
                }
            }
            .overlay {
                if let celebration {
                    CelebrationOverlayView(
                        presentation: celebration.presentation,
                        trigger: celebration.trigger,
                        hasNext: celebration.hasNext,
                        onDismiss: { center.dismissCurrent() }
                    )
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: celebration)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: toastAmount)
    }
}

extension View {
    /// Shows the app's reward loop (celebration overlay + XP toast) on top of
    /// this view. Needs a `RewardCenter` in the environment; without one it
    /// does nothing (previews).
    func rewardOverlay() -> some View {
        modifier(RewardOverlay())
    }
}
