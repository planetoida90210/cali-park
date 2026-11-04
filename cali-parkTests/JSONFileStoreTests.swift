import Foundation
import Testing
@testable import cali_park

// MARK: - Helpers

private final class BundleToken {}

private enum StoreTestSupport {
    static func makeDirectory() throws -> URL {
        let directory = try TemporaryDirectory.make("JSONFileStoreTests")
        return directory
    }

    /// Copies a golden fixture into `directory` under the store's real file name.
    static func installFixture(_ name: String, as fileName: String, in directory: URL) throws -> URL {
        let source = try #require(Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"))
        let destination = directory.appending(path: fileName)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    static func write(_ text: String, to fileName: String, in directory: URL) throws -> URL {
        let url = directory.appending(path: fileName)
        try Data(text.utf8).write(to: url)
        return url
    }

    /// Files whose name starts with `<base>.corrupt-`.
    static func quarantineCopies(of base: String, in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("\(base).corrupt-") }
    }

    static func topLevelObject(at url: URL) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        return try #require(object as? [String: Any])
    }

    /// 2026-11-03T21:15:00Z
    static let fixedNow = Date(timeIntervalSince1970: 1_793_740_500)
}

// MARK: - Golden fixtures (legacy on-disk format)

@Suite("Golden fixtures decode through the real stores", .temporaryDirectories)
struct GoldenFixtureTests {
    @Test
    func workoutLogFixtureDecodes() throws {
        let directory = try StoreTestSupport.makeDirectory()
        _ = try StoreTestSupport.installFixture("workout-log-legacy", as: "workout-log.json", in: directory)

        #expect(try FileWorkoutLogStore(directory: directory).load() == StoreFixtures.workoutLog)
    }

    @Test
    func workoutPlansFixtureDecodes() throws {
        let directory = try StoreTestSupport.makeDirectory()
        _ = try StoreTestSupport.installFixture("workout-plans-legacy", as: "workout-plans.json", in: directory)
        #expect(try FileWorkoutPlanStore(directory: directory, calendar: TestCalendar.utc).load() == StoreFixtures.workoutPlans)
    }

    @Test
    func placementFixtureDecodes() throws {
        let directory = try StoreTestSupport.makeDirectory()
        _ = try StoreTestSupport.installFixture("skill-placement-legacy", as: "skill-placement.json", in: directory)

        #expect(try FileSkillPlacementStore(directory: directory).load() == StoreFixtures.placement)
    }

    @Test
    func progressFixtureDecodes() throws {
        let directory = try StoreTestSupport.makeDirectory()
        _ = try StoreTestSupport.installFixture("skill-progress-legacy", as: "skill-progress.json", in: directory)

        #expect(try FileSkillProgressStore(directory: directory).load() == StoreFixtures.progress)
    }

    @Test
    func writingOverLegacyFileKeepsEntriesAndAddsEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.installFixture("workout-log-legacy", as: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)
        let added = WorkoutLogEntry(exerciseID: StoreFixtures.pullUpsID,
                                    date: StoreFixtures.october2,
                                    sets: [LoggedSet(reps: 10)])

        try store.append(added)

        #expect(try store.load() == StoreFixtures.workoutLog + [added])
        let object = try StoreTestSupport.topLevelObject(at: url)
        #expect(object["schemaVersion"] as? Int == 1)
        #expect((object["payload"] as? [Any])?.count == 4)
    }

    @Test
    func writingOverLegacyPlacementAddsEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.installFixture("skill-placement-legacy", as: "skill-placement.json", in: directory)
        let store = FileSkillPlacementStore(directory: directory)
        var updated = try #require(try store.load())
        updated.declaredStepByPath[.dip] = ExerciseCatalog.dipsID

        try store.save(updated)

        #expect(try store.load() == updated)
        #expect(try StoreTestSupport.topLevelObject(at: url)["schemaVersion"] as? Int == 2)
    }
}

// MARK: - Envelope round-trip

@Suite("Versioned envelope round-trip", .temporaryDirectories)
struct EnvelopeRoundTripTests {
    @Test
    func workoutLogRoundTripsThroughEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        try FileWorkoutLogStore(directory: directory).append(contentsOf: StoreFixtures.workoutLog)

        let url = directory.appending(path: "workout-log.json")
        let object = try StoreTestSupport.topLevelObject(at: url)
        #expect(object["schemaVersion"] as? Int == JSONFileFormat.currentSchemaVersion)
        #expect(object["payload"] is [Any])
        #expect(try FileWorkoutLogStore(directory: directory).load() == StoreFixtures.workoutLog)
    }

    @Test
    func workoutPlansRoundTripThroughEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let writer = FileWorkoutPlanStore(directory: directory)
        for plan in StoreFixtures.workoutPlans { try writer.save(plan) }

        let object = try StoreTestSupport.topLevelObject(at: directory.appending(path: "workout-plans.json"))
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(try FileWorkoutPlanStore(directory: directory).load() == StoreFixtures.workoutPlans)
    }

    @Test
    func placementRoundTripsThroughEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        try FileSkillPlacementStore(directory: directory).save(StoreFixtures.placement)

        let object = try StoreTestSupport.topLevelObject(at: directory.appending(path: "skill-placement.json"))
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(object["payload"] is [String: Any])
        #expect(try FileSkillPlacementStore(directory: directory).load() == StoreFixtures.placement)
    }

    @Test
    func progressRoundTripsThroughEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        try FileSkillProgressStore(directory: directory).save(StoreFixtures.progress)

        let object = try StoreTestSupport.topLevelObject(at: directory.appending(path: "skill-progress.json"))
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(try FileSkillProgressStore(directory: directory).load() == StoreFixtures.progress)
    }

    @Test
    func envelopeDatesAreISO8601WholeSeconds() throws {
        let directory = try StoreTestSupport.makeDirectory()
        try FileSkillPlacementStore(directory: directory).save(StoreFixtures.placement)

        let text = try String(contentsOf: directory.appending(path: "skill-placement.json"), encoding: .utf8)
        #expect(text.contains("\"declaredAt\":\"2026-10-01T07:30:00Z\""))
    }
}

// MARK: - Missing file

@Suite("Missing file means first launch", .temporaryDirectories)
struct MissingFileTests {
    @Test
    func missingFilesReadAsEmpty() throws {
        let directory = try StoreTestSupport.makeDirectory()

        #expect(try FileWorkoutLogStore(directory: directory).load().isEmpty)
        #expect(try FileWorkoutPlanStore(directory: directory).load().isEmpty)
        #expect(try FileSkillPlacementStore(directory: directory).load() == nil)
        #expect(try FileSkillProgressStore(directory: directory).load() == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path()).isEmpty)
    }

    @Test
    func deleteOnMissingFileWritesEmptyEnvelope() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let store = FileWorkoutLogStore(directory: directory)

        try store.delete(id: UUID())

        #expect(try store.load().isEmpty)
    }
}

// MARK: - Corrupt file is preserved

@Suite("Corrupt file is preserved, never overwritten", .temporaryDirectories)
struct CorruptFileTests {
    private static let garbage = #"[{"id": "not-a-uuid", "sets": "#

    @Test
    func corruptLogThrowsAndIsCopiedAside() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.write(Self.garbage, to: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)

        let error = #expect(throws: JSONFileStoreError.self) { try store.load() }

        guard case .undecodable(let file, let copy?, _) = error else {
            Issue.record("Expected .undecodable with a preserved copy, got \(String(describing: error))")
            return
        }
        #expect(file == url)
        #expect(copy.lastPathComponent.hasPrefix("workout-log.corrupt-"))
        #expect(copy.pathExtension == "json")
        #expect(try Data(contentsOf: copy) == Data(Self.garbage.utf8))
    }

    @Test
    func corruptLogRefusesEveryWriteAndStaysByteIdentical() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.write(Self.garbage, to: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)
        let entry = WorkoutLogEntry(exerciseID: StoreFixtures.pullUpsID,
                                    date: StoreFixtures.october1,
                                    sets: [LoggedSet(reps: 5)])

        #expect(throws: JSONFileStoreError.self) { try store.append(entry) }
        #expect(throws: JSONFileStoreError.self) { try store.append(contentsOf: [entry]) }
        #expect(throws: JSONFileStoreError.self) { try store.delete(id: entry.id) }

        #expect(try Data(contentsOf: url) == Data(Self.garbage.utf8))
    }

    @Test
    func corruptPlansRefuseWrites() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.write(Self.garbage, to: "workout-plans.json", in: directory)
        let store = FileWorkoutPlanStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.save(WorkoutPlan(name: "Nowy")) }
        #expect(throws: JSONFileStoreError.self) { try store.delete(id: UUID()) }
        #expect(try Data(contentsOf: url) == Data(Self.garbage.utf8))
    }

    @Test
    func corruptPlacementIsNotTreatedAsMissingAndRefusesSave() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.write("{}", to: "skill-placement.json", in: directory)
        let store = FileSkillPlacementStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.save(StoreFixtures.placement) }
        #expect(try String(contentsOf: url, encoding: .utf8) == "{}")
    }

    @Test
    func corruptProgressRefusesSave() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.write("[1, 2]", to: "skill-progress.json", in: directory)
        let store = FileSkillProgressStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.save(.empty) }
        #expect(try String(contentsOf: url, encoding: .utf8) == "[1, 2]")
    }

    @Test
    func oneBadRecordStillFailsLoudlyInsteadOfDroppingTheRest() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let good = try StoreTestSupport.installFixture("workout-log-legacy", as: "source.json", in: directory)
        var text = try String(contentsOf: good, encoding: .utf8)
        // Turn the plank set duration into a string: one undecodable record.
        text = text.replacingOccurrences(of: #""durationSeconds":45"#, with: #""durationSeconds":"45""#)
        let url = try StoreTestSupport.write(text, to: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) {
            try store.append(WorkoutLogEntry(exerciseID: StoreFixtures.pullUpsID, sets: [LoggedSet(reps: 1)]))
        }
        #expect(try String(contentsOf: url, encoding: .utf8) == text)
    }

    @Test
    func repeatedReadsLeaveASingleQuarantineCopy() throws {
        let directory = try StoreTestSupport.makeDirectory()
        _ = try StoreTestSupport.write(Self.garbage, to: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)

        for _ in 0..<3 {
            #expect(throws: JSONFileStoreError.self) { try store.load() }
        }

        #expect(try StoreTestSupport.quarantineCopies(of: "workout-log", in: directory).count == 1)
    }

    @Test
    func quarantineNameCarriesTheTimestamp() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = try StoreTestSupport.write("nope", to: "numbers.json", in: directory)
        let store = JSONFileStore<[Int]>(fileURL: url, logCategory: "Test", now: { StoreTestSupport.fixedNow })

        let error = #expect(throws: JSONFileStoreError.self) { try store.read() }

        guard case .undecodable(_, let copy?, _) = error else {
            Issue.record("Expected a preserved copy, got \(String(describing: error))")
            return
        }
        #expect(copy.lastPathComponent == "numbers.corrupt-20261103T211500Z.json")
    }

    @Test
    func differentCorruptContentsInTheSameSecondGetSeparateCopies() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let url = directory.appending(path: "numbers.json")
        let store = JSONFileStore<[Int]>(fileURL: url, logCategory: "Test", now: { StoreTestSupport.fixedNow })

        try Data("first".utf8).write(to: url)
        #expect(throws: JSONFileStoreError.self) { try store.read() }
        try Data("second".utf8).write(to: url)
        #expect(throws: JSONFileStoreError.self) { try store.read() }

        let names = try StoreTestSupport.quarantineCopies(of: "numbers", in: directory).map(\.lastPathComponent).sorted()
        #expect(names == ["numbers.corrupt-20261103T211500Z-1.json", "numbers.corrupt-20261103T211500Z.json"])
    }

    @Test
    func newerSchemaVersionIsRefusedNotOverwritten() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let text = #"{"schemaVersion":99,"payload":[]}"#
        let url = try StoreTestSupport.write(text, to: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)

        let error = #expect(throws: JSONFileStoreError.self) { try store.load() }
        guard case .unsupportedSchemaVersion(99, _, _) = error else {
            Issue.record("Expected .unsupportedSchemaVersion(99), got \(String(describing: error))")
            return
        }
        #expect(throws: JSONFileStoreError.self) {
            try store.append(WorkoutLogEntry(exerciseID: StoreFixtures.pullUpsID, sets: [LoggedSet(reps: 1)]))
        }
        #expect(try String(contentsOf: url, encoding: .utf8) == text)
    }

    @Test
    func unreadableFileThrowsAndRefusesWrites() throws {
        let directory = try StoreTestSupport.makeDirectory()
        // A directory where the file should be cannot be read as data.
        let url = directory.appending(path: "workout-plans.json", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        let store = FileWorkoutPlanStore(directory: directory)

        let error = #expect(throws: JSONFileStoreError.self) { try store.load() }
        guard case .unreadable = error else {
            Issue.record("Expected .unreadable, got \(String(describing: error))")
            return
        }
        #expect(throws: JSONFileStoreError.self) { try store.save(WorkoutPlan(name: "Nowy")) }
    }
}

// MARK: - View models surface load failures

private struct BrokenPlanStore: WorkoutPlanStoring {
    struct ReadError: Error {}
    func load() throws -> [WorkoutPlan] { throw ReadError() }
    func save(_ plan: WorkoutPlan) throws { throw ReadError() }
    func delete(id: UUID) throws { throw ReadError() }
}

private struct BrokenPlacementStore: PlacementStoring {
    struct ReadError: Error {}
    func load() throws -> SkillPlacement? { throw ReadError() }
    func save(_ placement: SkillPlacement) throws { throw ReadError() }
}

/// Unreadable progress record that counts save attempts.
private final class BrokenProgressStore: SkillProgressStoring {
    struct ReadError: Error {}
    private(set) var saveAttempts = 0
    func load() throws -> SkillProgress? { throw ReadError() }
    func save(_ progress: SkillProgress) throws { saveAttempts += 1 }
}

@MainActor
@Suite("View models show an error instead of an empty journal", .temporaryDirectories)
struct StoreLoadFailureViewModelTests {
    @Test
    func historyReportsLoadFailureOnce() {
        let viewModel = WorkoutHistoryViewModel(store: UnreadableWorkoutLogStore())

        #expect(viewModel.hasLoadError)
        #expect(viewModel.errorMessage == StoreLoadFailure.message)

        viewModel.errorMessage = nil
        viewModel.reload()
        #expect(viewModel.errorMessage == nil) // no alert on every appear
        #expect(viewModel.hasLoadError)
    }

    @Test
    func plansListReportsLoadFailure() {
        let viewModel = WorkoutPlansViewModel(service: .testing(BrokenPlanStore()))
        viewModel.reload()

        #expect(viewModel.hasLoadError)
        #expect(viewModel.errorMessage == StoreLoadFailure.message)
    }

    @Test
    func sessionDetailReportsLoadFailure() {
        let viewModel = WorkoutSessionDetailViewModel(sessionID: UUID(), store: UnreadableWorkoutLogStore())

        #expect(viewModel.hasLoadError)
        #expect(viewModel.errorMessage == StoreLoadFailure.message)
    }

    @Test
    func homeShowsWhatLoadedAndReportsWhatDidNot() throws {
        let entry = WorkoutLogEntry(exerciseID: StoreFixtures.pullUpsID,
                                    date: StoreFixtures.october1,
                                    sets: [LoggedSet(reps: 5)])
        let viewModel = HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: [entry]),
            planService: .testing(BrokenPlanStore()),
            placementStore: InMemorySkillPlacementStore(),
            goalStore: InMemoryWeeklyGoalStore()
        )

        #expect(viewModel.entries == [entry])
        #expect(viewModel.hasLoadError)
        #expect(viewModel.errorMessage == StoreLoadFailure.message)
    }

    @Test
    func skillsDoNotOfferCalibrationWhenPlacementIsUnreadable() {
        let viewModel = TrainingStack(placementStore: BrokenPlacementStore()).skillPaths()

        #expect(viewModel.hasLoadError)
        #expect(!viewModel.needsCalibration)
        #expect(viewModel.errorMessage == StoreLoadFailure.message)
    }

    @Test
    func skillsOfferCalibrationWhenPlacementIsMissing() {
        let viewModel = TrainingStack().skillPaths()

        #expect(!viewModel.hasLoadError)
        #expect(viewModel.needsCalibration)
    }

    @Test
    func unreadableProgressSkipsRewardsInsteadOfRebaselining() throws {
        let progressStore = BrokenProgressStore()
        let logStore = InMemoryWorkoutLogStore()
        try logStore.append(WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                            date: StoreFixtures.october1,
                                            sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]))

        let stack = TrainingStack(logStore: logStore, progressStore: progressStore)

        #expect(progressStore.saveAttempts == 0)
        #expect(stack.rewards.currentCelebration == nil)
        #expect(!stack.skillPaths().hasLoadError) // logs and placement still show
    }

    @Test
    func loggingASetOverACorruptJournalKeepsTheFile() throws {
        let directory = try StoreTestSupport.makeDirectory()
        let garbage = #"[{"broken": true"#
        let url = try StoreTestSupport.write(garbage, to: "workout-log.json", in: directory)
        let store = FileWorkoutLogStore(directory: directory)

        let history = WorkoutHistoryViewModel(store: store)
        #expect(history.hasLoadError)

        let exercise = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID))
        let setPad = WorkoutLogViewModel(exercise: exercise, store: store)
        setPad.input.appendDigit(5)
        setPad.save()

        #expect(setPad.errorMessage != nil)
        #expect(try String(contentsOf: url, encoding: .utf8) == garbage)
    }
}
