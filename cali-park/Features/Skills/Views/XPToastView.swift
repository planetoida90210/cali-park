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
            .accessibilityLabel("Zdobyto \(amount) XP")
    }
}

// MARK: - Preview
#Preview {
    Color.appBackground.ignoresSafeArea()
        .overlay(alignment: .top) {
            XPToastView(amount: 34)
                .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
}
