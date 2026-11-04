import Foundation
import Testing
@testable import cali_park

// MARK: - Helpers

private struct MigrationRig {
    let root: URL
    let documents: URL
    let applicationSupport: URL
    let destination: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appending(path: "StoreDirectoryMigrationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        documents = root.appending(path: "Documents", directoryHint: .isDirectory)
        applicationSupport = root.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        destination = applicationSupport.appending(path: "CaliPark", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }

    func migration(fileManager: FileManager = .default) -> StoreDirectoryMigration {
        StoreDirectoryMigration(legacyDirectory: documents, directory: destination, fileManager: fileManager)
    }

    @discardableResult
    func write(_ text: String, _ name: String, in directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: name)
        try Data(text.utf8).write(to: url)
        return url
    }

    func contents(_ name: String, in directory: URL) throws -> String {
        try String(decoding: Data(contentsOf: directory.appending(path: name)), as: UTF8.self)
    }

    func exists(_ name: String, in directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: directory.appending(path: name).path(percentEncoded: false))
    }
}

/// Fails every move, like a full disk or a permissions problem.
private final class FailingMoveFileManager: FileManager {
    struct MoveError: Error {}
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        throw MoveError()
    }
}

/// Cannot create directories, so the store directory never exists.
private final class FailingCreateFileManager: FileManager {
    struct CreateError: Error {}
    override func createDirectory(at url: URL,
                                  withIntermediateDirectories createIntermediates: Bool,
                                  attributes: [FileAttributeKey: Any]? = nil) throws {
        throw CreateError()
    }
}

// MARK: - StoreDirectoryMigration

@Suite("Store files move from Documents to Application Support")
struct StoreDirectoryMigrationTests {
    @Test
    func freshInstallCreatesTheStoreDirectoryAndUsesIt() throws {
        let rig = try MigrationRig()

        let locations = rig.migration().run()

        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: rig.destination.path(percentEncoded: false), isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        for file in StoreFile.allCases {
            #expect(locations.directory(for: file) == rig.destination)
        }
        // A first write lands in the new directory.
        let log = FileWorkoutLogStore(directory: locations.directory(for: .workoutLog))
        try log.append(WorkoutLogEntry(exerciseID: StoreFixtures.pullUpsID, date: StoreFixtures.october1,
                                       sets: [LoggedSet(reps: 5)]))
        #expect(rig.exists("workout-log.json", in: rig.destination))
        #expect(!rig.exists("workout-log.json", in: rig.documents))
    }

    @Test
    func existingDocumentsFilesMoveAndStillLoad() throws {
        let rig = try MigrationRig()
        for file in StoreFile.allCases {
            try rig.write("{\"from\": \"documents\"}", file.fileName, in: rig.documents)
        }
        let fixture = try #require(Bundle(for: MigrationBundleToken.self).url(forResource: "workout-log-legacy",
                                                                           withExtension: "json"))
        try FileManager.default.removeItem(at: rig.documents.appending(path: "workout-log.json"))
        try FileManager.default.copyItem(at: fixture, to: rig.documents.appending(path: "workout-log.json"))

        let locations = rig.migration().run()

        for file in StoreFile.allCases {
            #expect(locations.directory(for: file) == rig.destination)
            #expect(rig.exists(file.fileName, in: rig.destination))
            #expect(!rig.exists(file.fileName, in: rig.documents))
        }
        let log = FileWorkoutLogStore(directory: locations.directory(for: .workoutLog))
        #expect(try log.load() == StoreFixtures.workoutLog)
    }

    @Test
    func whenBothExistTheDestinationWinsAndDocumentsStaysUntouched() throws {
        let rig = try MigrationRig()
        try rig.write("old", "workout-log.json", in: rig.documents)
        try rig.write("new", "workout-log.json", in: rig.destination)

        let locations = rig.migration().run()

        #expect(locations.directory(for: .workoutLog) == rig.destination)
        #expect(try rig.contents("workout-log.json", in: rig.destination) == "new")
        #expect(try rig.contents("workout-log.json", in: rig.documents) == "old")
    }

    @Test
    func quarantineCopiesMoveWithTheirStore() throws {
        let rig = try MigrationRig()
        try rig.write("broken", "workout-plans.json", in: rig.documents)
        try rig.write("broken", "workout-plans.corrupt-20261103T211500Z.json", in: rig.documents)
        // Not a store file: stays where it is.
        try rig.write("x", "notes.txt", in: rig.documents)

        _ = rig.migration().run()

        #expect(rig.exists("workout-plans.json", in: rig.destination))
        #expect(rig.exists("workout-plans.corrupt-20261103T211500Z.json", in: rig.destination))
        #expect(!rig.exists("workout-plans.corrupt-20261103T211500Z.json", in: rig.documents))
        #expect(rig.exists("notes.txt", in: rig.documents))
        #expect(!rig.exists("notes.txt", in: rig.destination))
    }

    @Test
    func aQuarantineCopyNeverOverwritesOneAtTheDestination() throws {
        let rig = try MigrationRig()
        let name = "weekly-goal.corrupt-20261103T211500Z.json"
        try rig.write("documents", name, in: rig.documents)
        try rig.write("destination", name, in: rig.destination)

        _ = rig.migration().run()

        #expect(try rig.contents(name, in: rig.destination) == "destination")
        #expect(try rig.contents(name, in: rig.documents) == "documents")
    }

    @Test
    func aFailedMoveKeepsTheSourceAndReadsItThere() throws {
        let rig = try MigrationRig()
        let fixture = try #require(Bundle(for: MigrationBundleToken.self).url(forResource: "workout-log-legacy",
                                                                           withExtension: "json"))
        try FileManager.default.copyItem(at: fixture, to: rig.documents.appending(path: "workout-log.json"))
        let original = try Data(contentsOf: rig.documents.appending(path: "workout-log.json"))

        let locations = rig.migration(fileManager: FailingMoveFileManager()).run()

        #expect(locations.directory(for: .workoutLog) == rig.documents)
        #expect(try Data(contentsOf: rig.documents.appending(path: "workout-log.json")) == original)
        #expect(!rig.exists("workout-log.json", in: rig.destination))
        // No silent empty journal: the store still reads the old entries.
        #expect(try FileWorkoutLogStore(directory: locations.directory(for: .workoutLog)).load()
                == StoreFixtures.workoutLog)
        // Files that had nothing to move use the new directory.
        #expect(locations.directory(for: .weeklyGoal) == rig.destination)
    }

    @Test
    func withoutTheStoreDirectoryEveryStoreStaysInDocuments() throws {
        let rig = try MigrationRig()
        try rig.write("[]", "workout-plans.json", in: rig.documents)

        let locations = rig.migration(fileManager: FailingCreateFileManager()).run()

        for file in StoreFile.allCases {
            #expect(locations.directory(for: file) == rig.documents)
        }
        #expect(rig.exists("workout-plans.json", in: rig.documents))
    }

    @Test
    func runningAgainChangesNothing() throws {
        let rig = try MigrationRig()
        try rig.write("log", "workout-log.json", in: rig.documents)

        let first = rig.migration().run()
        try rig.write("later", "workout-log.json", in: rig.destination)
        let second = rig.migration().run()

        #expect(first == second)
        #expect(try rig.contents("workout-log.json", in: rig.destination) == "later")
    }

    /// Changing a raw value would orphan the file every device already has.
    @Test
    func storeFileNamesArePinned() {
        #expect(StoreFile.allCases.map(\.fileName) == [
            "workout-log.json", "workout-plans.json", "skill-placement.json",
            "skill-progress.json", "weekly-goal.json", "favorite-parks.json",
            "favorite-exercises.json"
        ])
        #expect(StoreFile.workoutPlans.quarantinePrefix == "workout-plans.corrupt-")
    }

    @Test
    func theLiveDirectoryIsApplicationSupportCaliPark() {
        #expect(StoreDirectoryMigration.defaultDirectory
                == URL.applicationSupportDirectory.appending(path: "CaliPark", directoryHint: .isDirectory))
        #expect(StoreDirectoryMigration.live().legacyDirectory == URL.documentsDirectory)
    }
}

private final class MigrationBundleToken {}

// MARK: - CoreDataScaffoldCleanup

@Suite("The empty Core Data store is deleted once")
struct CoreDataScaffoldCleanupTests {
    private func makeDefaults() throws -> UserDefaults {
        let name = "CoreDataScaffoldCleanupTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test
    func removesOnlyTheScaffoldFilesAndRemembersIt() throws {
        let rig = try MigrationRig()
        let defaults = try makeDefaults()
        for name in CoreDataScaffoldCleanup.fileNames {
            try rig.write("sqlite", name, in: rig.applicationSupport)
        }
        try rig.write("keep", "cali_park.sqlite.bak", in: rig.applicationSupport)
        try rig.write("keep", "workout-log.json", in: rig.destination)

        CoreDataScaffoldCleanup(directory: rig.applicationSupport, defaults: defaults).run()

        for name in CoreDataScaffoldCleanup.fileNames {
            #expect(!rig.exists(name, in: rig.applicationSupport))
        }
        #expect(rig.exists("cali_park.sqlite.bak", in: rig.applicationSupport))
        #expect(rig.exists("workout-log.json", in: rig.destination))
        #expect(defaults.bool(forKey: DefaultsKey.didRemoveCoreDataScaffold.rawValue))
    }

    @Test
    func runsOnlyOnce() throws {
        let rig = try MigrationRig()
        let defaults = try makeDefaults()
        let cleanup = CoreDataScaffoldCleanup(directory: rig.applicationSupport, defaults: defaults)
        cleanup.run()

        // A store with the same name created later (say Core Data returns) is
        // left alone.
        try rig.write("future", "cali_park.sqlite", in: rig.applicationSupport)
        cleanup.run()

        #expect(rig.exists("cali_park.sqlite", in: rig.applicationSupport))
    }

    @Test
    func aMissingDirectoryCountsAsCleaned() throws {
        let rig = try MigrationRig()
        let defaults = try makeDefaults()

        CoreDataScaffoldCleanup(directory: rig.root.appending(path: "nowhere"), defaults: defaults).run()

        #expect(defaults.bool(forKey: DefaultsKey.didRemoveCoreDataScaffold.rawValue))
    }
}

// MARK: - DefaultsKey

@Suite("UserDefaults keys")
struct DefaultsKeyTests {
    /// The raw values are what devices already store; renaming one would reset
    /// onboarding or a hint for every user.
    @Test
    func keysKeepTheirStoredStrings() {
        #expect(DefaultsKey.hasCompletedOnboarding.rawValue == "hasCompletedOnboarding")
        #expect(DefaultsKey.hasSeenSetPadHint.rawValue == "hasSeenSetPadHint")
        #expect(DefaultsKey.didRemoveCoreDataScaffold.rawValue == "didRemoveCoreDataScaffold")
        #expect(DefaultsKey.enabledModules.rawValue == "enabledModules")
        #expect(DefaultsKey.allCases.count == 4)
    }
}
