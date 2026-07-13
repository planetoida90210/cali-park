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
            Group {
                if hasCompletedOnboarding {
                    MainTabView(environment: environment)
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(environment)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
