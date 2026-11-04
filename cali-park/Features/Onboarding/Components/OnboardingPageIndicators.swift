import SwiftUI

// MARK: - OnboardingPageIndicators
/// One dot per onboarding page, the current one in the accent color.
struct OnboardingPageIndicators: View {
    let currentPage: OnboardingPage

    var body: some View {
        HStack {
            ForEach(OnboardingPage.allCases, id: \.self) { page in
                Circle()
                    .fill(currentPage == page ? Color.accent : Color.divider)
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }
}
