import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures
private enum AsyncFixture {
    /// A pull-up entry whose single set has `reps` reps; `SlowWorkoutLogStore`
    /// keys its delays and failures on that number.
    static func entry(_ reps: Int, at date: Date = TestDate.reference) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, date: date, sets: [LoggedSet(reps: reps)])
    }
}

// MARK: - Ordering and failures
@MainActor
@Suite("TrainingJournal async writes")
struct TrainingJournalAsyncWriteTests {
    @Test
    func writesRunOneAtATimeInTheOrderTheyWereCalled() async throws {
        let store = SlowWorkoutLogStore(slowReps: 1)
        let journal = TrainingJournal(store: store)
        let first = AsyncFixture.entry(1)
        let second = AsyncFixture.entry(2)

        // Both calls are issued before either write finishes.
        async let a: Void = journal.log(first)
        async let b: Void = journal.log(second)
        _ = try await (a, b)

        #expect(store.started == [1, 2])
        #expect(store.saved.map(\.id) == [first.id, second.id])
        #expect(journal.entries.map(\.id) == [first.id, second.id])
        #expect(journal.revision == 3)
    }

    @Test
    func aFailedWriteThrowsToItsCallerAndTheNextOneStillRuns() async {
        let store = SlowWorkoutLogStore(failingReps: 1)
        let journal = TrainingJournal(store: store)
        let revision = journal.revision
        let kept = AsyncFixture.entry(2)

        let failed = Task { try await journal.log(AsyncFixture.entry(1)) }
        let succeeded = Task { try await journal.log(kept) }

        await #expect(throws: SlowWorkoutLogStore.WriteFailed.self) { try await failed.value }
        await #expect(throws: Never.self) { try await succeeded.value }
        #expect(journal.entries.map(\.id) == [kept.id])
        #expect(journal.revision == revision + 1)
    }

    @Test
    func entriesChangeOnlyOnceTheStoreSavedTheWrite() async throws {
        let store = SlowWorkoutLogStore(slowReps: 1)
        let journal = TrainingJournal(store: store)
        let entry = AsyncFixture.entry(1)

        let save = Task { try await journal.log(entry) }
        await Task.yield()
        #expect(journal.entries.isEmpty)

        try await save.value
        #expect(journal.entries.map(\.id) == [entry.id])
    }

    @Test
    func cancellingTheCallerDoesNotStopAStartedWrite() async {
        let store = SlowWorkoutLogStore(slowReps: 1)
        let journal = TrainingJournal(store: store)
        let entry = AsyncFixture.entry(1)

        let save = Task { try await journal.log(entry) }
        await Task.yield()
        save.cancel()
        _ = await save.result
        await journal.waitForPendingWrites()

        #expect(store.saved.map(\.id) == [entry.id])
        #expect(journal.entries.map(\.id) == [entry.id])
    }

    @Test
    func replaceAllRunsAfterWriteRightAfterTheChange() async throws {
        let journal = TrainingJournal(store: InMemoryWorkoutLogStore())
        var handlerRuns = 0
        journal.onChange { handlerRuns += 1 }
        let imported = [AsyncFixture.entry(5), AsyncFixture.entry(6)]
        var seen: (count: Int, handlerRuns: Int)?

        try await journal.replaceAll(imported, afterWrite: {
            seen = (journal.entries.count, handlerRuns)
        })

        #expect(seen?.count == 2)
        #expect(seen?.handlerRuns == 1)
    }

    @Test
    func newestFirstMatchesAFullSortAfterAppendsAndDeletes() async throws {
        let base = TestDate.reference
        // Equal dates on purpose: a stable sort keeps them in saved order.
        let initial = [0, 3, 3, 1, 5].enumerated().map { index, hours in
            AsyncFixture.entry(index, at: base.addingTimeInterval(Double(hours) * 3600))
        }
        let journal = TrainingJournal(store: InMemoryWorkoutLogStore(initial: initial))

        try await journal.log(AsyncFixture.entry(10, at: base.addingTimeInterval(3 * 3600)))
        try await journal.logSession([AsyncFixture.entry(11, at: base.addingTimeInterval(9 * 3600)),
                                      AsyncFixture.entry(12, at: base.addingTimeInterval(-3600)),
                                      AsyncFixture.entry(13, at: base.addingTimeInterval(3 * 3600))])
        try await journal.delete(ids: [initial[1].id, initial[4].id])

        #expect(journal.newestFirst == journal.entries.sorted { $0.date > $1.date })
        #expect(journal.entries.count == 7)
    }

    @Test
    func deletingIdsThatAreNotThereChangesNothing() async throws {
        let journal = TrainingJournal(store: InMemoryWorkoutLogStore(initial: [AsyncFixture.entry(1)]))
        let revision = journal.revision

        try await journal.delete(ids: [UUID()])

        #expect(journal.revision == revision)
    }
}

// MARK: - Double taps while a save is in flight
@MainActor
@Suite("Saving twice while the first save is written")
struct InFlightSaveTests {
    @Test
    func setPadSavesOnceWhenTappedTwiceDuringTheWrite() async throws {
        let store = SlowWorkoutLogStore(slowReps: 8)
        let journal = TrainingJournal(store: store)
        let exercise = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID))
        let pad = WorkoutLogViewModel(exercise: exercise, journal: journal)
        pad.input.appendDigit(8)

        async let first: Void = pad.save()
        async let second: Void = pad.save()
        _ = await (first, second)

        #expect(store.saved.count == 1)
        #expect(pad.didSave)
        #expect(!pad.isSaving)
    }

    @Test
    func quickWorkoutFinishesOnceWhenTappedTwiceDuringTheWrite() async throws {
        let store = SlowWorkoutLogStore(slowReps: 8)
        let journal = TrainingJournal(store: store)
        let session = QuickWorkoutViewModel(journal: journal, clock: { TestDate.reference })
        let exercise = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID))
        session.addExercise(exercise, sets: [LoggedSet(reps: 8)])

        async let first: Void = session.finish()
        async let second: Void = session.finish()
        _ = await (first, second)

        #expect(store.saved.count == 1)
        #expect(session.didFinish)
        #expect(session.canFinish)
    }
}

// MARK: - JSONFileStore off the main actor
@MainActor
@Suite("JSONFileStore async operations", .temporaryDirectories)
struct JSONFileStoreAsyncTests {
    @Test
    func asyncWritesRoundTripThroughTheSameFile() async throws {
        let directory = try TemporaryDirectory.make()
        let file = JSONFileStore<[Int]>(fileURL: directory.appending(path: "numbers.json"), logCategory: "Test")

        #expect(try await file.read() == nil)
        try await file.write([1, 2])
        try await file.update(initial: []) { $0.append(3) }

        #expect(try await file.read() == [1, 2, 3])
    }

    @Test
    func asyncWritesAreRefusedOverAnUndecodableFile() async throws {
        let directory = try TemporaryDirectory.make()
        let url = directory.appending(path: "numbers.json")
        let garbage = Data("{ not json".utf8)
        try garbage.write(to: url)
        let file = JSONFileStore<[Int]>(fileURL: url, logCategory: "Test")

        await #expect(throws: JSONFileStoreError.self) { try await file.write([1]) }
        await #expect(throws: JSONFileStoreError.self) { try await file.update(initial: []) { $0.append(1) } }
        #expect(try Data(contentsOf: url) == garbage)
    }

    @Test
    func fileJournalWritesAndReloadsTheSameEntries() async throws {
        let directory = try TemporaryDirectory.make()
        let store = FileWorkoutLogStore(directory: directory)
        let journal = TrainingJournal(store: store)
        let kept = AsyncFixture.entry(5)
        let dropped = AsyncFixture.entry(6)

        try await journal.logSession([kept, dropped])
        try await journal.delete(ids: [dropped.id])

        #expect(try store.load() == [kept])
        #expect(TrainingJournal(store: store).entries == journal.entries)
    }
}
