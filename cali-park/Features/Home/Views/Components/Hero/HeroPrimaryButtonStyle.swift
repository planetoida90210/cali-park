import SwiftUI

// MARK: - HeroPrimaryButtonStyle
/// The hero call-to-action (e.g. "Rozpocznij"): the app's accent fill,
/// full-width by design so it reads as the main move.
struct HeroPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLarge)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accent)
            .clipShape(.rect(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
