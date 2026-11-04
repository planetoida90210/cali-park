import SwiftUI

// MARK: - OnboardingPlacementPage
/// The level test page: where the athlete already is on each progression path.
struct OnboardingPlacementPage: View {
    let viewModel: PlacementCalibrationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Co już potrafisz?")
                        .font(.appTitle2)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Zaczniesz od właściwego szczebla, nie od zera.")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }

                PlacementFormView(viewModel: viewModel)
            }
            .padding(.vertical, 8)
        }
    }
}
