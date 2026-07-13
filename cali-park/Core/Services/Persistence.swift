//
//  Persistence.swift
//  cali-park
//
//  Created by Emanuel Delawarski on 04/05/2025.
//

import CoreData
import OSLog

/// Empty scaffold kept for future local persistence. The data model currently
/// has no entities on purpose – the backend decision is deliberately deferred.
/// Store-loading failures degrade gracefully (logged) instead of crashing,
/// because nothing critical depends on Core Data yet.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private static let logger = Logger(subsystem: "com.michalbryk.cali-park", category: "Persistence")

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "cali_park")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                Self.logger.error("Nie udało się załadować magazynu Core Data: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
