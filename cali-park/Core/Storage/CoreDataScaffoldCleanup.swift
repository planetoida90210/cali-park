import Foundation
import os

// MARK: - CoreDataScaffoldCleanup
/// Deletes the empty SQLite store that the removed Core Data scaffold created
/// at every launch up to 1.0 (`cali_park.sqlite` plus its `-wal` and `-shm`
/// files in Application Support). Its model had no entities (`<elements/>`),
/// so the files never held user data.
///
/// Runs once: only these exact names are removed, and a defaults flag stops
/// it from touching a store with the same name if Core Data ever returns.
/// Missing files count as removed; a file that cannot be removed is logged
/// and retried on the next launch.
nonisolated struct CoreDataScaffoldCleanup {
    static let fileNames = ["cali_park.sqlite", "cali_park.sqlite-wal", "cali_park.sqlite-shm"]

    /// Where `NSPersistentContainer` kept the store: Application Support.
    let directory: URL
    let defaults: UserDefaults
    let fileManager: FileManager

    private static let logger = AppLog.logger(category: "CoreDataScaffoldCleanup")

    init(directory: URL = .applicationSupportDirectory,
         defaults: UserDefaults = .standard,
         fileManager: FileManager = .default) {
        self.directory = directory
        self.defaults = defaults
        self.fileManager = fileManager
    }

    func run() {
        let key = DefaultsKey.didRemoveCoreDataScaffold.rawValue
        guard !defaults.bool(forKey: key) else { return }

        var removedAll = true
        for name in Self.fileNames {
            let url = directory.appending(path: name)
            guard fileManager.fileExists(atPath: url.path(percentEncoded: false)) else { continue }
            do {
                try fileManager.removeItem(at: url)
            } catch {
                removedAll = false
                Self.logger.error("Cannot remove \(name, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
        if removedAll {
            defaults.set(true, forKey: key)
        }
    }
}
