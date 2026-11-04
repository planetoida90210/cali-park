import SwiftUI

// MARK: - OnboardingWelcomePage
/// The first onboarding page: the hero glyph and the welcome text.
struct OnboardingWelcomePage: View {
    /// Scales the hero glyphs with Dynamic Type while keeping their base size.
    @ScaledMetric private var heroIconSize: CGFloat = 80

    var body: some View {
        // Centered while it fits; at large text sizes it scrolls instead of
        // cutting the title and the text short.
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var content: some View {
        VStack(spacing: 32) {
            Image(systemName: "figure.gymnastics")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text("Witaj w CaliPark")
                .font(.appLargeTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Trenuj kalistenikę krok po kroku, od szczebla, na którym już jesteś.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .frame(maxWidth: .infinity)
    }
}
