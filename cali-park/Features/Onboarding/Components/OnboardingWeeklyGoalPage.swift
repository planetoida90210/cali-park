import SwiftUI

// MARK: - OnboardingWeeklyGoalPage
/// The last step: how many days a week to train, defaulting to the chosen
/// program's frequency. Other goal kinds are set later in Profile or on Home.
struct OnboardingWeeklyGoalPage: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cel tygodniowy")
                        .font(.appTitle2)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text(hint)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }

                Stepper(
                    value: Binding(
                        get: { viewModel.trainingDays },
                        set: { viewModel.setTrainingDays($0) }
                    ),
                    in: WeeklyGoal.trainingDaysRange
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PolishPlural.trainingDays(viewModel.trainingDays))
                            .font(.appTitle3)
                            .foregroundStyle(Color.textPrimary)
                        Text("w tygodniu, w dowolne dni")
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding()
                .background(Color.componentBackground)
                .clipShape(.rect(cornerRadius: AppRadius.medium))

                Text("Odpoczynek jest elastyczny: liczy się, ile dni w tygodniu trenujesz, nie które. Cel i pauzę zmienisz później w Profilu.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var hint: String {
        if let program = viewModel.chosenProgramName {
            let days = PolishPlural.days(viewModel.suggestedTrainingDays)
            return String(localized: "Program \(program) to \(days) w tygodniu. Ustaw, ile dni chcesz trenować.")
        } else {
            return String(localized: "Ile dni w tygodniu chcesz trenować? Na start polecamy 3.")
        }
    }
}
