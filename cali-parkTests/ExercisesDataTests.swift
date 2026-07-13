//
//  ExercisesDataTests.swift
//  cali-parkTests
//
//  Sprint 1 — data foundation for the Exercises tab:
//  catalog integrity and workout log store roundtrip.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - ExerciseCatalog integrity

struct ExerciseCatalogTests {
    @Test
    func catalogHasExpectedSize() {
        #expect((15...20).contains(ExerciseCatalog.all.count))
    }

    @Test
    func identifiersAreUnique() {
        let ids = ExerciseCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test
    func namesAreUnique() {
        let names = ExerciseCatalog.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test
    func everyCategoryIsRepresented() {
        let categories = Set(ExerciseCatalog.all.map(\.category))
        #expect(categories == Set(ExerciseCategory.allCases))
    }

    @Test(arguments: ExerciseCatalog.all)
    func exerciseIsComplete(exercise: Exercise) {
        #expect(!exercise.name.isEmpty)
        #expect(!exercise.description.isEmpty)
        #expect(!exercise.muscleGroups.isEmpty)
        #expect(exercise.instructions.count >= 3)
        #expect(exercise.instructions.allSatisfy { !$0.isEmpty })
        #expect(exercise.symbolName.hasPrefix("figure."))
    }

    @Test(arguments: [ExerciseCatalog.pullUpsID, ExerciseCatalog.muscleUpID, ExerciseCatalog.plancheID])
    func lookupResolvesStableID(id: UUID) {
        #expect(ExerciseCatalog.exercise(withID: id)?.id == id)
    }

    @Test
    func lookupReturnsNilForUnknownID() {
        #expect(ExerciseCatalog.exercise(withID: UUID()) == nil)
    }

    @Test
    func exerciseRoundtripsThroughJSON() throws {
        let original = ExerciseCatalog.all
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([Exercise].self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - FileWorkoutLogStore roundtrip

struct FileWorkoutLogStoreTests {
    /// Fresh store in a unique temporary directory per test.
    private func makeStore() throws -> FileWorkoutLogStore {
        let directory = URL.temporaryDirectory
            .appending(path: "workout-log-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return FileWorkoutLogStore(directory: directory)
    }

    /// Whole-second date: ISO 8601 encoding drops sub-second precision,
    /// so fixtures must not rely on it for equality.
    private let fixedDate = Date(timeIntervalSince1970: 1_750_000_000)

    private func makeEntry(reps: [Int] = [6, 6, 8]) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: fixedDate,
            sets: reps.map { LoggedSet(reps: $0) }
        )
    }

    @Test
    func loadFromEmptyDirectoryReturnsNoEntries() throws {
        let store = try makeStore()
        #expect(store.load().isEmpty)
    }

    @Test
    func appendedEntriesRoundtrip() throws {
        let store = try makeStore()
        let first = makeEntry(reps: [6, 6, 8])
        let second = makeEntry(reps: [10])

        try store.append(first)
        try store.append(second)

        #expect(store.load() == [first, second])
    }

    @Test
    func deleteRemovesOnlyTargetEntry() throws {
        let store = try makeStore()
        let keep = makeEntry(reps: [12])
        let remove = makeEntry(reps: [5])
        try store.append(keep)
        try store.append(remove)

        try store.delete(id: remove.id)

        #expect(store.load() == [keep])
    }

    @Test
    func deleteUnknownIDLeavesEntriesIntact() throws {
        let store = try makeStore()
        let entry = makeEntry()
        try store.append(entry)

        try store.delete(id: UUID())

        #expect(store.load() == [entry])
    }

    @Test
    func persistenceSurvivesStoreReinstantiation() throws {
        let directory = URL.temporaryDirectory
            .appending(path: "workout-log-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let entry = makeEntry()
        try FileWorkoutLogStore(directory: directory).append(entry)

        let reopened = FileWorkoutLogStore(directory: directory)
        #expect(reopened.load() == [entry])
    }

    @Test
    func totalRepsSumsAllSets() {
        #expect(makeEntry(reps: [6, 6, 6, 8, 6]).totalReps == 32)
    }
}
