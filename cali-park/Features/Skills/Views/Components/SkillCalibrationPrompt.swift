import SwiftUI

// MARK: - SkillCalibrationPrompt
/// First-contact nudge for athletes who skipped onboarding placement.
struct SkillCalibrationPrompt: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ustaw swój poziom")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Zaczniesz od właściwego szczebla, nie od zera.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            Button("Ustaw poziom", action: action)
                .buttonStyle(.accent(.compact))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
    }
}
