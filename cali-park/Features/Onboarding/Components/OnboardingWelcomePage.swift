import SwiftUI

// MARK: - OnboardingWelcomePage
/// The first onboarding page: the hero glyph and the welcome text.
struct OnboardingWelcomePage: View {
    /// Scales the hero glyphs with Dynamic Type while keeping their base size.
    @ScaledMetric private var heroIconSize: CGFloat = 80

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.gymnastics")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Color.accent)

            Text("Witaj w CaliPark")
                .font(.appLargeTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Trenuj kalistenikę krok po kroku, od szczebla, na którym już jesteś.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}
