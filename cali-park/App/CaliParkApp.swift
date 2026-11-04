//
//  CaliParkApp.swift
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
            CaliParkApp.main()
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

    /// The app's composition root: the real stores, or in a Debug build
    /// launched by the UI tests with `-uitest-reset`, a seeded in-memory
    /// environment (`UITestSeed`).
    @MainActor
    static func makeEnvironment(_ process: ProcessInfo = .processInfo) -> AppEnvironment {
        #if DEBUG
        if let seed = UITestSeed.requested(arguments: process.arguments, environment: process.environment) {
            // Sheets and pushes appear at once, so each UI test step only
            // waits for the app to go idle, not for a transition.
            UIView.setAnimationsEnabled(false)
            return .uiTest(seed, defaults: AppEnvironment.uiTestDefaults())
        }
        #endif
        return .live()
    }
}

// MARK: - UnitTestHostApp
/// The app while hosting unit tests: one empty window, no `AppEnvironment`.
struct UnitTestHostApp: App {
    var body: some Scene {
        WindowGroup { Color.clear }
    }
}

// MARK: - CaliParkApp
struct CaliParkApp: App {
    /// Composition root, built once and passed down the view tree through
    /// initializers. `@State` only keeps the one instance; nothing observes it.
    @State private var environment = AppLaunch.makeEnvironment()

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

    /// Every `@AppStorage` below reads the environment's `UserDefaults`
    /// (`.standard` in the app, the UI tests' own suite in a seeded launch).
    private var appContent: some View {
        AppRootView(environment: environment)
            .defaultAppStorage(environment.defaults)
    }
}
