//
//  QuickWorkoutTests.swift
//  cali-parkTests
//
//  Sprint 5 — "Szybki trening": session accumulation/save, backward-compatible
//  sessionID persistence, and history grouping.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Shared stubs

/// Always fails — verifies error surfacing (pattern: `FailingReviewsService`).
private struct FailingWorkoutLogStore: WorkoutLogStoring {
    struct SampleError: Error {}
    func load() -> [WorkoutLogEntry] { [] }
    func append(_ entry: WorkoutLogEntry) throws { throw SampleError() }
    func delete(id: UUID) throws { throw SampleError() }
}

// MARK: - WorkoutLogEntry Codable (backward compatibility)

struct WorkoutLogEntryCodableTests {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    @Test
    func sessionIDRoundtrips() throws {
        let sessionID = UUID()
        let entry = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            sets: [LoggedSet(reps: 6)],
            sessionID: sessionID
        )

        let data = try Self.encoder.encode(entry)
        let decoded = try Self.decoder.decode(WorkoutLogEntry.self, from: data)

        #expect(decoded.sessionID == sessionID)
        #expect(decoded == entry)
    }

    /// Entries saved before sessions existed have no `sessionID` key and must
    /// still decode (to `nil`).
    @Test
    func legacyJSONWithoutSessionIDDecodesToNil() throws {
        let json = """
        {
            "id": "11111111-1111-4111-8111-111111111111",
            "exerciseID": "E0000000-0000-4000-8000-000000000001",
            "date": "2026-01-01T10:00:00Z",
            "sets": [{ "reps": 6 }, { "reps": 8 }]
        }
        """
        let data = Data(json.utf8)

        let decoded = try Self.decoder.decode(WorkoutLogEntry.self, from: data)

        #expect(decoded.sessionID == nil)
        #expect(decoded.note == nil)
        #expect(decoded.sets.map(\.reps) == [6, 8])
    }
}

// MARK: - QuickWorkoutViewModel

@MainActor
struct QuickWorkoutViewModelTests {
    private func sets(_ reps: Int...) -> [LoggedSet] {
        reps.map { LoggedSet(reps: $0) }
    }

    @Test
    func addExerciseAccumulatesItems() {
        let viewModel = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())

        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6, 6, 8))
        viewModel.addExercise(ExerciseCatalog.all[1], sets: sets(10, 10))

        #expect(viewModel.exerciseCount == 2)
        #expect(viewModel.totalSets == 5)
        #expect(viewModel.canFinish)
    }

    @Test
    func addExerciseIgnoresEmptySets() {
        let viewModel = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())

        viewModel.addExercise(ExerciseCatalog.all[0], sets: [])

        #expect(viewModel.isEmpty)
        #expect(!viewModel.canFinish)
    }

    @Test
    func removeDropsTheItem() {
        let viewModel = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6))
        viewModel.addExercise(ExerciseCatalog.all[1], sets: sets(8))

        let doomed = viewModel.items[0]
        viewModel.remove(doomed)

        #expect(viewModel.exerciseCount == 1)
        #expect(viewModel.items.first?.exercise.id == ExerciseCatalog.all[1].id)
    }

    @Test
    func finishPersistsEveryExerciseUnderOneSession() throws {
        let store = InMemoryWorkoutLogStore()
        let viewModel = QuickWorkoutViewModel(store: store)
        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6, 6, 8))
        viewModel.addExercise(ExerciseCatalog.all[1], sets: sets(10))

        viewModel.finish()

        let saved = store.load()
        #expect(saved.count == 2)
        #expect(viewModel.didFinish)
        #expect(viewModel.errorMessage == nil)

        // All entries share one non-nil sessionID and one timestamp.
        let sessionIDs = Set(saved.compactMap(\.sessionID))
        #expect(sessionIDs.count == 1)
        let dates = Set(saved.map(\.date))
        #expect(dates.count == 1)

        let exerciseIDs = saved.map(\.exerciseID)
        #expect(exerciseIDs.contains(ExerciseCatalog.all[0].id))
        #expect(exerciseIDs.contains(ExerciseCatalog.all[1].id))
    }

    @Test
    func finishWithNoItemsIsANoOp() {
        let store = InMemoryWorkoutLogStore()
        let viewModel = QuickWorkoutViewModel(store: store)

        viewModel.finish()

        #expect(store.load().isEmpty)
        #expect(!viewModel.didFinish)
    }

    @Test
    func finishFailureSurfacesErrorAndSavesNothing() {
        let viewModel = QuickWorkoutViewModel(store: FailingWorkoutLogStore())
        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6))

        viewModel.finish()

        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.didFinish)
    }
}

// MARK: - Batch append

struct WorkoutLogStoreBatchTests {
    @Test
    func inMemoryBatchAppendPersistsAll() throws {
        let store = InMemoryWorkoutLogStore()
        let entries = [
            WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 6)]),
            WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 10)])
        ]

        try store.append(contentsOf: entries)

        #expect(store.load().count == 2)
    }

    @Test
    func fileStoreBatchAppendPersistsAllInOneWrite() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileWorkoutLogStore(directory: directory)
        let sessionID = UUID()
        let entries = [
            WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 6)], sessionID: sessionID),
            WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, sets: [LoggedSet(reps: 8)], sessionID: sessionID)
        ]

        try store.append(contentsOf: entries)

        let reloaded = FileWorkoutLogStore(directory: directory).load()
        #expect(reloaded.count == 2)
        #expect(Set(reloaded.compactMap(\.sessionID)) == [sessionID])
    }
}

// MARK: - History grouping

@MainActor
struct WorkoutHistorySectionTests {
    @Test
    func sessionEntriesCollapseIntoOneSection() {
        let sessionID = UUID()
        let a = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                date: Date(timeIntervalSince1970: 3_000),
                                sets: [LoggedSet(reps: 6)],
                                sessionID: sessionID)
        let b = WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID,
                                date: Date(timeIntervalSince1970: 3_000),
                                sets: [LoggedSet(reps: 8)],
                                sessionID: sessionID)
        let viewModel = WorkoutHistoryViewModel(store: InMemoryWorkoutLogStore(initial: [a, b]))

        let sections = viewModel.sections
        #expect(sections.count == 1)
        #expect(sections[0].isSession)
        #expect(sections[0].entries.count == 2)
        #expect(sections[0].totalReps == 14)
    }

    @Test
    func standaloneEntriesStaySeparateEvenOnTheSameDay() {
        let day = Date(timeIntervalSince1970: 5_000)
        let x = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, date: day, sets: [LoggedSet(reps: 6)])
        let y = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, date: day, sets: [LoggedSet(reps: 10)])
        let viewModel = WorkoutHistoryViewModel(store: InMemoryWorkoutLogStore(initial: [x, y]))

        let sections = viewModel.sections
        #expect(sections.count == 2)
        #expect(sections.allSatisfy { !$0.isSession })
    }

    @Test
    func sectionsAreSortedNewestFirst() {
        let sessionID = UUID()
        let sessionA = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                       date: Date(timeIntervalSince1970: 3_000),
                                       sets: [LoggedSet(reps: 6)],
                                       sessionID: sessionID)
        let sessionB = WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID,
                                       date: Date(timeIntervalSince1970: 3_000),
                                       sets: [LoggedSet(reps: 8)],
                                       sessionID: sessionID)
        let newest = WorkoutLogEntry(exerciseID: ExerciseCatalog.squatsID,
                                     date: Date(timeIntervalSince1970: 5_000),
                                     sets: [LoggedSet(reps: 20)])
        let oldest = WorkoutLogEntry(exerciseID: ExerciseCatalog.plankID,
                                     date: Date(timeIntervalSince1970: 1_000),
                                     sets: [LoggedSet(reps: 30)])
        let viewModel = WorkoutHistoryViewModel(
            store: InMemoryWorkoutLogStore(initial: [sessionA, sessionB, newest, oldest])
        )

        let sections = viewModel.sections
        #expect(sections.count == 3)
        #expect(sections[0].entries == [newest])   // 5000
        #expect(sections[1].isSession)             // 3000 session
        #expect(sections[2].entries == [oldest])   // 1000
    }
}
