//
//  cali_parkApp.swift
//  cali-park
//
//  Created by Emanuel Delawarski on 04/05/2025.
//

import SwiftUI

@main
struct cali_parkApp: App {
    let persistenceController = PersistenceController.shared
    /// Composition root – built once and injected down the view tree.
    @StateObject private var environment = AppEnvironment()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Throwaway map-look prototype (ticket 011), opened with `-PrototypeMapLook`.
            if Self.mapLookOptions.isEnabled {
                MapLookPrototypeRoot(options: Self.mapLookOptions)
            } else if Self.parkSubmissionOptions.isEnabled {
                // Throwaway Park Submission prototype (ticket 013), opened with `-PrototypeParkSubmission`.
                ParkSubmissionPrototypeRoot(options: Self.parkSubmissionOptions)
            } else if Self.parkCardOptions.isEnabled {
                // Throwaway Park card prototype (ticket 023), opened with `-PrototypeParkCard`.
                ParkCardPrototypeRoot(options: Self.parkCardOptions)
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
    }

    #if DEBUG
    private static let mapLookOptions = MapLookLaunchOptions()
    private static let parkSubmissionOptions = ParkSubmissionLaunchOptions()
    private static let parkCardOptions = ParkCardLaunchOptions()
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
        .environmentObject(environment)
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        // Re-sync plan reminders on launch and on every return to the app:
        // tops up interval reminders and repairs any drift.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await environment.workoutPlanService.syncReminders()
        }
    }
}
