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
    @AppStorage(DefaultsKey.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding: Bool = false

    @State private var viewModel: OnboardingViewModel

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: environment.makeOnboardingViewModel())
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                TabView(selection: pageBinding) {
                    OnboardingWelcomePage().onboardingPage(.welcome)
                    OnboardingPlacementPage(viewModel: viewModel.calibration).onboardingPage(.placement)
                    ProgramChoiceView(viewModel: viewModel.programChoice).onboardingPage(.program)
                    OnboardingWeeklyGoalPage(viewModel: viewModel).onboardingPage(.weeklyGoal)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack {
                    OnboardingPageIndicators(currentPage: viewModel.page)
                        .padding(.bottom, 20)

                    OnboardingNavigationButtons(viewModel: viewModel, onFinish: finish)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
        }
        .errorAlert($viewModel.errorMessage, onDismiss: { hasCompletedOnboarding = true })
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

    /// Saves the placement, the program's plans and the weekly goal. A
    /// failure shows an alert that finishes onboarding when closed.
    private func finish() {
        Task {
            if await viewModel.finish() {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Page identity
private extension View {
    /// Tags the page for the `TabView` and names it for the UI tests
    /// ("onboarding.page.program").
    func onboardingPage(_ page: OnboardingPage) -> some View {
        accessibilityElement(children: .contain)
            .accessibilityIdentifier("onboarding.page.\(page.identifier)")
            .tag(page)
    }
}

private extension OnboardingPage {
    var identifier: String {
        switch self {
        case .welcome: "welcome"
        case .placement: "placement"
        case .program: "program"
        case .weeklyGoal: "weeklyGoal"
        }
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    OnboardingView(environment: .seeded())
        .preferredColorScheme(.dark)
}
#endif
