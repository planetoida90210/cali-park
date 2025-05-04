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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .preferredColorScheme(.dark)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView()
                    .preferredColorScheme(.dark)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
