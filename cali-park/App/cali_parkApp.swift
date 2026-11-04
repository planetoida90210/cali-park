//
//  cali_parkApp.swift
//  cali-park
//
//  Created by Emanuel Delawarski on 04/05/2025.
//

import SwiftUI

@main
struct cali_parkApp: App {
    /// Composition root, built once and passed down the view tree through
    /// initializers. `@State` only keeps the one instance; nothing observes it.
    @State private var environment = AppEnvironment.live()
    @AppStorage(DefaultsKey.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        let planService = environment.workoutPlanService
        WindowGroup {
            #if DEBUG
            // Throwaway Park Submission prototype (ticket 013), opened with `-PrototypeParkSubmission`.
            if Self.parkSubmissionOptions.isEnabled {
                ParkSubmissionPrototypeRoot(options: Self.parkSubmissionOptions)
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
        // Tops up the dated plan reminders while the app isn't opened. Each
        // sync requests the next refresh about a day later.
        .backgroundTask(.appRefresh(AppRefreshScheduler.taskIdentifier)) {
            await planService.syncReminders()
        }
    }

    #if DEBUG
    private static let parkSubmissionOptions = ParkSubmissionLaunchOptions()
    #endif

    private var appContent: some View {
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
