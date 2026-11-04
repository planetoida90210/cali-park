import SwiftUI

// MARK: - XPToastView
/// A discreet "+N XP" pill shown briefly after a save that earned experience.
/// It never blocks: the Skills view schedules its own dismissal.
struct XPToastView: View {
    let amount: Int

    var body: some View {
        Text("+\(amount) XP")
            .font(.buttonMedium)
            .monospacedDigit()
            .foregroundStyle(Color.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accent, in: .capsule)
            .accessibilityLabel(Self.spokenText(amount: amount))
    }

    /// What VoiceOver reads and announces for the toast: "Zdobyto 30 XP".
    static func spokenText(amount: Int) -> String {
        "Zdobyto \(amount) XP"
    }

    /// How far below the top safe area the toast sits, so it clears the
    /// inline navigation bar and its title instead of covering them.
    static let navigationBarClearance: CGFloat = 60
}

// MARK: - Preview
#Preview {
    Color.appBackground.ignoresSafeArea()
        .overlay(alignment: .top) {
            XPToastView(amount: 34)
                .padding(.top, XPToastView.navigationBarClearance)
        }
        .preferredColorScheme(.dark)
}
