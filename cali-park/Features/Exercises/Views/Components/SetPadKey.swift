import SwiftUI

// MARK: - SetPadKey
struct SetPadKey<Content: View>: View {
    let label: String
    var isAccent = false
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .font(.appTitle3)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(isAccent ? Color.accent : Color.componentBackground)
                .foregroundStyle(isAccent ? Color.black : Color.textPrimary)
                .clipShape(.rect(cornerRadius: AppRadius.medium))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}
