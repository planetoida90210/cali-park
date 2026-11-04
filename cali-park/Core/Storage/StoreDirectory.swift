import Foundation
import os

// MARK: - StoreFile
/// The JSON files the `File…` stores keep. The raw values are the file names
/// already on devices: never rename one.
enum StoreFile: String, CaseIterable, Sendable {
    case workoutLog = "workout-log.json"
    case workoutPlans = "workout-plans.json"
    case skillPlacement = "skill-placement.json"
    case skillProgress = "skill-progress.json"
    case weeklyGoal = "weekly-goal.json"

    var fileName: String { rawValue }

    /// The prefix of this file's quarantine copies (`JSONFileStore` writes
    /// `<name>.corrupt-<timestamp>.json` next to a file it cannot read).
    var quarantinePrefix: String {
        (fileName as NSString).deletingPathExtension + ".corrupt-"
    }
}

// MARK: - StoreLocations
/// Where each store file lives after `StoreDirectoryMigration` ran: normally
/// the app's store directory, or the legacy Documents directory for a file
/// that could not be moved yet.
struct StoreLocations: Equatable, Sendable {
    private let directories: [StoreFile: URL]
    private let fallback: URL

    init(directories: [StoreFile: URL], fallback: URL) {
        self.directories = directories
        self.fallback = fallback
    }

    /// The directory to pass to the store that owns `file`.
    func directory(for file: StoreFile) -> URL {
        directories[file] ?? fallback
    }
}

// MARK: - StoreDirectoryMigration
/// Moves the store files from Documents (where versions up to 1.0 kept them)
/// to `Application Support/CaliPark/`, once, before any store loads.
///
/// Documents is meant for files the user sees; internal app state belongs in
/// Application Support. Both are included in iCloud and device backups, so the
/// move changes nothing for backups (and nothing here excludes files from
/// them).
///
/// Per file, every launch (it is idempotent and cheap):
/// - destination exists → use it. A leftover source file is kept and logged,
///   never copied over the destination and never deleted.
/// - source missing → use the destination (fresh install or already moved).
/// - source only → move it. If the move fails, the source stays where it was
///   and the store reads it there, so a failed move can never surface as an
///   empty journal. The next launch tries again.
///
/// Quarantine copies (`<name>.corrupt-…`) move along when their name is free
/// at the destination; they are never read by the app, so a failure there is
/// only logged.
struct StoreDirectoryMigration {
    /// Where versions up to 1.0 kept the files.
    let legacyDirectory: URL
    /// Where the stores keep their files from now on.
    let directory: URL
    let files: [StoreFile]
    let fileManager: FileManager

    private static let logger = AppLog.logger(category: "StoreDirectoryMigration")

    init(legacyDirectory: URL,
         directory: URL,
         files: [StoreFile] = StoreFile.allCases,
         fileManager: FileManager = .default) {
        self.legacyDirectory = legacyDirectory
        self.directory = directory
        self.files = files
        self.fileManager = fileManager
    }

    /// The app's real directories: Documents → `Application Support/CaliPark/`.
    static func live() -> StoreDirectoryMigration {
        StoreDirectoryMigration(legacyDirectory: .documentsDirectory, directory: defaultDirectory)
    }

    /// `Application Support/CaliPark/`.
    static var defaultDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "CaliPark", directoryHint: .isDirectory)
    }

    // MARK: Run
    /// Creates the store directory, moves what can be moved, and returns where
    /// each store should read.
    func run() -> StoreLocations {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            // Without the directory nothing can be written there; keep every
            // store in the legacy directory, where existing files still are.
            Self.logger.error("Cannot create the store directory: \(String(describing: error), privacy: .public)")
            return StoreLocations(directories: [:], fallback: legacyDirectory)
        }

        var directories: [StoreFile: URL] = [:]
        for file in files {
            directories[file] = migrate(file)
            moveQuarantineCopies(of: file)
        }
        return StoreLocations(directories: directories, fallback: directory)
    }

    /// Moves one store file if needed; returns the directory it now lives in.
    private func migrate(_ file: StoreFile) -> URL {
        let source = legacyDirectory.appending(path: file.fileName)
        let destination = directory.appending(path: file.fileName)
        let hasSource = fileManager.fileExists(atPath: source.path(percentEncoded: false))
        let hasDestination = fileManager.fileExists(atPath: destination.path(percentEncoded: false))

        switch (hasSource, hasDestination) {
        case (_, true):
            if hasSource {
                Self.logger.error("""
                    \(file.fileName, privacy: .public) exists in Documents and in the store directory; \
                    keeping the store directory copy, Documents left untouched
                    """)
            }
            return directory
        case (false, false):
            return directory
        case (true, false):
            do {
                try fileManager.moveItem(at: source, to: destination)
                Self.logger.info("Moved \(file.fileName, privacy: .public) to the store directory")
                return directory
            } catch {
                Self.logger.error("""
                    Cannot move \(file.fileName, privacy: .public); reading it from Documents: \
                    \(String(describing: error), privacy: .public)
                    """)
                return legacyDirectory
            }
        }
    }

    private func moveQuarantineCopies(of file: StoreFile) {
        let names = (try? fileManager.contentsOfDirectory(atPath: legacyDirectory.path(percentEncoded: false))) ?? []
        for name in names where name.hasPrefix(file.quarantinePrefix) {
            let source = legacyDirectory.appending(path: name)
            let destination = directory.appending(path: name)
            guard !fileManager.fileExists(atPath: destination.path(percentEncoded: false)) else { continue }
            do {
                try fileManager.moveItem(at: source, to: destination)
            } catch {
                Self.logger.error("Cannot move \(name, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }
}
