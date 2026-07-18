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
    func catalogHoldsMainMovementsAndVariants() {
        // The original 19 stay the library; variants are appended on top.
        #expect(ExerciseCatalog.mainMovements.count == 19)
        #expect(ExerciseCatalog.all.count >= 60)
    }

    @Test
    func libraryShowsOnlyMainMovements() {
        #expect(ExerciseCatalog.mainMovements.allSatisfy { $0.variantOf == nil })
    }

    @Test
    func firstTwoCatalogEntriesAreStable() {
        // Many tests and views reference `all[0]`/`all[1]`; variants must be
        // appended, never inserted, so these indices never shift.
        #expect(ExerciseCatalog.all[0].id == ExerciseCatalog.pullUpsID)
        #expect(ExerciseCatalog.all[1].id == ExerciseCatalog.pushUpsID)
    }

    @Test
    func originalNineteenIdentifiersAreUnchanged() {
        let original: [UUID] = [
            ExerciseCatalog.pullUpsID, ExerciseCatalog.pushUpsID, ExerciseCatalog.dipsID,
            ExerciseCatalog.squatsID, ExerciseCatalog.lungesID, ExerciseCatalog.plankID,
            ExerciseCatalog.australianPullUpsID, ExerciseCatalog.hangingLegRaisesID,
            ExerciseCatalog.pistolSquatsID, ExerciseCatalog.wallHandstandPushUpsID,
            ExerciseCatalog.lSitID, ExerciseCatalog.archerPullUpsID, ExerciseCatalog.ringDipsID,
            ExerciseCatalog.bridgeID, ExerciseCatalog.muscleUpID, ExerciseCatalog.frontLeverID,
            ExerciseCatalog.humanFlagID, ExerciseCatalog.plancheID, ExerciseCatalog.backLeverID
        ]
        #expect(Set(original) == Set(ExerciseCatalog.mainMovements.map(\.id)))
    }

    @Test
    func everyVariantPointsAtAMainMovement() {
        let mainIDs = Set(ExerciseCatalog.mainMovements.map(\.id))
        for exercise in ExerciseCatalog.all {
            guard let parent = exercise.variantOf else { continue }
            // Flat, one-level hierarchy: a variant's parent is always a main
            // movement, never another variant.
            #expect(mainIDs.contains(parent))
        }
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

    @Test
    func decodingWithoutNewFieldsUsesDefaults() throws {
        // Payload shaped like a catalog snapshot encoded before `measurement`
        // and `variantOf` existed — both must decode to their defaults.
        let json = """
        {
            "id": "E0000000-0000-4000-8000-000000000001",
            "name": "Podciągnięcia",
            "category": "basic",
            "muscleGroups": ["back", "arms"],
            "description": "Test",
            "instructions": ["a", "b", "c"],
            "symbolName": "figure.climbing"
        }
        """
        let decoded = try JSONDecoder().decode(Exercise.self, from: Data(json.utf8))
        #expect(decoded.measurement == .reps)
        #expect(decoded.variantOf == nil)
        #expect(decoded.equipment.isEmpty)
    }

    @Test
    func isometricHoldsAreMeasuredInSeconds() {
        // Statics must be second-based so the SetPad (SK2) logs holds correctly.
        let holdIDs: [UUID] = [
            ExerciseCatalog.plankID, ExerciseCatalog.lSitID, ExerciseCatalog.frontLeverID,
            ExerciseCatalog.backLeverID, ExerciseCatalog.plancheID, ExerciseCatalog.humanFlagID
        ]
        for id in holdIDs {
            #expect(ExerciseCatalog.exercise(withID: id)?.measurement == .seconds)
        }
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
