//
//  cali_parkApp.swift
//  cali-park
//
//  Created by Emanuel Delawarski on 04/05/2025.
//

import SwiftUI

// MARK: - Entry point
/// Starts the real app, or an empty one when the process only hosts the unit
/// tests: those build their own in-memory environments, and must not move
/// store files, load the journal or schedule reminders on the simulator.
@main
enum AppLauncher {
    static func main() {
        if AppLaunch.isHostingUnitTests(ProcessInfo.processInfo.environment) {
            UnitTestHostApp.main()
        } else {
            cali_parkApp.main()
        }
    }
}

// MARK: - AppLaunch
nonisolated enum AppLaunch {
    /// Whether this process was started by XCTest to host the unit test
    /// bundle. UI tests launch the app as a separate process without this
    /// variable, so they still get the real app.
    static func isHostingUnitTests(_ environment: [String: String]) -> Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}

// MARK: - UnitTestHostApp
/// The app while hosting unit tests: one empty window, no `AppEnvironment`.
struct UnitTestHostApp: App {
    var body: some Scene {
        WindowGroup { Color.clear }
    }
}

// MARK: - cali_parkApp
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
