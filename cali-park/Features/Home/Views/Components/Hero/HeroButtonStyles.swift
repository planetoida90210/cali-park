import SwiftUI

// MARK: - Hero button styles
/// Non-deprecated button styles used by the hero call-to-actions. They mirror
/// the app's primary/secondary look (accent fill vs. accent ghost) but rely on
/// `clipShape`/`foregroundStyle` rather than the deprecated `cornerRadius`/
/// `foregroundColor`. Full-width by design so a hero CTA reads as the main move.

/// Filled accent action — the dominant CTA (e.g. "Rozpocznij").
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

/// Accent outline action — the supporting CTA (e.g. "Szybki trening").
struct HeroSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accent.opacity(0.6), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
