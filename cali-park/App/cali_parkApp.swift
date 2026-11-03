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

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Throwaway map-look prototype (ticket 011), opened with `-PrototypeMapLook`.
            if Self.mapLookOptions.isEnabled {
                MapLookPrototypeRoot(options: Self.mapLookOptions)
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
    }
}
