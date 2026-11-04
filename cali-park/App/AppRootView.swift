import SwiftUI

// MARK: - AppRootView
/// Onboarding until it is finished, then the tabs. Also re-syncs plan
/// reminders on launch and on every return to the app.
struct AppRootView: View {
    let environment: AppEnvironment
    /// Read from the `defaultAppStorage` the app sets to `environment.defaults`.
    @AppStorage(DefaultsKey.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(environment: environment)
            } else {
                OnboardingView(environment: environment)
            }
        }
        .preferredColorScheme(.dark)
        // Re-sync plan reminders on launch and on every return to the app:
        // tops up the dated reminders and repairs any drift.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await environment.workoutPlanService.syncReminders()
        }
    }
}
