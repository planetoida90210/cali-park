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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
