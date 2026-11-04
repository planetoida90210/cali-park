import SwiftUI

// MARK: - OnboardingView
/// First-run flow (ticket 026): welcome, the level test (where the athlete
/// already is on each progression path), "Program na start", and the weekly
/// goal. `OnboardingViewModel` owns the order and what each step suggests;
/// this view only lays the pages out.
///
/// There is no goals question (the program choice took its role) and no
/// location step: the map asks for location when it first opens.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var viewModel: OnboardingViewModel

    /// Scales the hero glyphs with Dynamic Type while keeping their base size.
    @ScaledMetric private var heroIconSize: CGFloat = 80

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: environment.makeOnboardingViewModel())
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                TabView(selection: pageBinding) {
                    welcomeView.tag(OnboardingPage.welcome)
                    placementView.tag(OnboardingPage.placement)
                    ProgramChoiceView(viewModel: viewModel.programChoice).tag(OnboardingPage.program)
                    OnboardingWeeklyGoalPage(viewModel: viewModel).tag(OnboardingPage.weeklyGoal)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack {
                    pageIndicators
                        .padding(.bottom, 20)

                    navigationButtons
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
        }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("Rozumiem", role: .cancel) { hasCompletedOnboarding = true }
        }
    }

    // Swipes go through the view model too, so each step's suggestion is
    // refreshed however the athlete reaches it.
    private var pageBinding: Binding<OnboardingPage> {
        Binding(
            get: { viewModel.page },
            set: { viewModel.show($0) }
        )
    }

    // Bridges the optional error to a Bool binding for `.alert`. Closing the
    // alert finishes onboarding with whatever could be saved.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    // MARK: - Navigation chrome

    private var pageIndicators: some View {
        HStack {
            ForEach(OnboardingPage.allCases, id: \.self) { page in
                Circle()
                    .fill(viewModel.page == page ? Color.accent : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }

    private var navigationButtons: some View {
        HStack {
            if viewModel.page.previous != nil {
                Button("Wróć") {
                    withAnimation { viewModel.goBack() }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Spacer()

            Button(viewModel.page.isLast ? "Rozpocznij" : "Dalej") {
                if viewModel.page.isLast {
                    finish()
                } else {
                    withAnimation { viewModel.goForward() }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isFinishing)
        }
    }

    /// Saves the placement, the program's plans and the weekly goal. A
    /// failure shows an alert that finishes onboarding when closed.
    private func finish() {
        Task {
            if await viewModel.finish() {
                hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - Pages

    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.gymnastics")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Color.accent)

            Text("Witaj w CaliPark")
                .font(.largeTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Trenuj kalistenikę krok po kroku, od szczebla, na którym już jesteś.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var placementView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Co już potrafisz?")
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)

                    Text("Zaczniesz od właściwego szczebla, nie od zera.")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }

                PlacementFormView(viewModel: viewModel.calibration)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - OnboardingWeeklyGoalPage
/// The last step: how many days a week to train, defaulting to the chosen
/// program's frequency. Other goal kinds are set later in Profile or on Home.
private struct OnboardingWeeklyGoalPage: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cel tygodniowy")
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)

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
                            .font(.title3)
                            .foregroundStyle(Color.textPrimary)
                        Text("w tygodniu, w dowolne dni")
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding()
                .background(Color.componentBackground)
                .clipShape(.rect(cornerRadius: 12))

                Text("Odpoczynek jest elastyczny: liczy się, ile dni w tygodniu trenujesz, nie które. Cel i pauzę zmienisz później w Profilu.")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var hint: String {
        if let program = viewModel.chosenProgramName {
            "Program \(program) to \(PolishPlural.days(viewModel.suggestedTrainingDays)) w tygodniu. Ustaw, ile dni chcesz trenować."
        } else {
            "Ile dni w tygodniu chcesz trenować? Na start polecamy 3."
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(environment: .seeded())
        .preferredColorScheme(.dark)
}
