//
//  SessionGroupingTests.swift
//  cali-parkTests
//
//  Pairs and circuits on the workout screen: blocks, round counting and
//  the rest after a round. Logging stays per exercise.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Blocks

@Suite("A session's items split into singles, pairs and circuits")
struct SessionGroupingTests {
    private struct Item: Identifiable, Equatable {
        let id: String
        let group: Int?
    }

    private static func kinds(_ items: [Item]) -> [[String]] {
        SessionGrouping.blocks(items, group: \.group).map { $0.items.map(\.id) }
    }

    @Test
    func singlesBeforeAPairShareOneBlock() {
        let items = [Item(id: "pull", group: nil), Item(id: "row", group: nil),
                     Item(id: "push", group: 1), Item(id: "legs", group: 1)]
        let blocks = SessionGrouping.blocks(items, group: \.group)

        #expect(blocks.map(\.kind) == [.singles, .group(1)])
        #expect(Self.kinds(items) == [["pull", "row"], ["push", "legs"]])
    }

    @Test
    func aGroupStaysTogetherAroundAnInsertedExercise() {
        let items = [Item(id: "a", group: 1), Item(id: "extra", group: nil), Item(id: "b", group: 1),
                     Item(id: "c", group: 2), Item(id: "d", group: 2)]
        #expect(Self.kinds(items) == [["a", "b"], ["extra"], ["c", "d"]])
    }

    @Test
    func blocksHaveStableDistinctIDs() {
        let items = [Item(id: "x", group: nil), Item(id: "a", group: 1), Item(id: "b", group: 1),
                     Item(id: "y", group: nil)]
        let ids = SessionGrouping.blocks(items, group: \.group).map(\.id)
        #expect(ids == ["singles-x", "group-1", "singles-y"])
    }

    @Test
    func noItemsGiveNoBlocks() {
        #expect(SessionGrouping.blocks([Item](), group: \.group).isEmpty)
    }
}

// MARK: - Rounds

@Suite("Round counter of a pair or circuit")
struct RoundTrackerTests {
    private static let start = TestDate.reference

    @Test
    func aPairCountsItsSetsAsRoundsAndRestsAfterEach() throws {
        let pair = [
            PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 8, restSeconds: 90, group: 1),
            PlannedExercise(exerciseID: ExerciseCatalog.squatsID, targetSets: 3, targetReps: 8, restSeconds: 90, group: 1)
        ]
        var tracker = try #require(RoundTracker(for: pair))
        #expect(tracker.rounds == 3...3)
        #expect(ProgramFormat.roundLabel(for: tracker) == "Runda 1/3")

        tracker.finishRound(at: Self.start)
        #expect(ProgramFormat.roundLabel(for: tracker) == "Runda 2/3")
        #expect(tracker.rest == DateInterval(start: Self.start, duration: 90))
        #expect(tracker.isResting(at: Self.start.addingTimeInterval(89)))
        #expect(!tracker.isResting(at: Self.start.addingTimeInterval(90)))
    }

    @Test
    func theLastRoundEndsWithoutARest() {
        var tracker = RoundTracker(rounds: 2...2, restSeconds: 90)
        tracker.finishRound(at: Self.start)
        tracker.endRest()
        tracker.finishRound(at: Self.start.addingTimeInterval(200))

        #expect(tracker.isFinished)
        #expect(tracker.rest == nil)
        #expect(ProgramFormat.roundLabel(for: tracker) == "2/2 rundy zrobione")

        tracker.finishRound(at: Self.start.addingTimeInterval(400))
        #expect(tracker.completed == 2)
    }

    @Test
    func aCircuitCountsUpToTheTopOfItsRangeWithTheDefaultRest() throws {
        let circuit = ProgramPrescriber.plans(for: ProgramCatalog.minimum, pathStates: ProgramFixtures.newcomer,
                                              today: ProgramFixtures.today)[0].exercises
        var tracker = try #require(RoundTracker(for: circuit))
        #expect(tracker.rounds == 2...6)
        #expect(tracker.restSeconds == RoundTracker.defaultCircuitRestSeconds)
        #expect(ProgramFormat.roundLabel(for: tracker) == "Runda 1 (2–6)")

        tracker.finishRound(at: Self.start)
        #expect(!tracker.hasMetMinimum)
        tracker.finishRound(at: Self.start)
        #expect(tracker.hasMetMinimum)
        #expect(ProgramFormat.roundLabel(for: tracker) == "Runda 3 (2–6)")

        for _ in 0..<4 { tracker.finishRound(at: Self.start) }
        #expect(ProgramFormat.roundLabel(for: tracker) == "6 rund zrobionych")
    }

    @Test
    func aGroupWithoutSetsOrRoundsHasNoCounter() {
        let group = [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, group: 1),
                     PlannedExercise(exerciseID: ExerciseCatalog.squatsID, group: 1)]
        #expect(RoundTracker(for: group) == nil)
    }

    @Test
    func aPairWithoutRestStartsNoTimer() {
        var tracker = RoundTracker(rounds: 3...3, restSeconds: 0)
        tracker.finishRound(at: Self.start)
        #expect(tracker.rest == nil)
        #expect(tracker.currentRound == 2)
    }
}

// MARK: - Workout screen

@MainActor
@Suite("A program plan's pairs and circuits on the workout screen", .timeLimit(.minutes(1)))
struct SessionGroupsInWorkoutTests {
    private static func session(_ program: TrainingProgram,
                                clock: @escaping () -> Date = { TestDate.reference }) -> QuickWorkoutViewModel {
        let plan = ProgramPrescriber.plans(for: program, pathStates: ProgramFixtures.newcomer,
                                           today: ProgramFixtures.today)[0]
        return QuickWorkoutViewModel(store: InMemoryWorkoutLogStore(), plan: plan,
                                     pathStates: ProgramFixtures.newcomer, logs: [], clock: clock)
    }

    @Test
    func fundamentalsShowsThreePairs() {
        let session = Self.session(ProgramCatalog.fundamentals)

        #expect(session.blocks.map(\.kind) == [.group(1), .group(2), .group(3)])
        #expect(session.blocks.allSatisfy { $0.items.count == 2 })
        #expect(session.groups[1]?.title == "Para 1")
        #expect(session.groups[1]?.instruction == "Na przemian, przerwa 90 s po każdej serii")
        #expect(session.groups[1]?.tracker?.rounds == 3...3)
    }

    @Test
    func firstPullUpKeepsItsSinglesAndOnePair() {
        let session = Self.session(ProgramCatalog.firstPullUp)
        #expect(session.blocks.map(\.kind) == [.singles, .group(1)])
        #expect(session.blocks[0].items.count == 2)
    }

    @Test
    func minimumIsOneCircuit() {
        let session = Self.session(ProgramCatalog.minimum)
        #expect(session.blocks.map(\.kind) == [.group(1)])
        #expect(session.groups[1]?.title == "Obwód")
        #expect(session.groups[1]?.instruction == "Jedno po drugim, przerwa po rundzie")
    }

    @Test
    func finishingARoundStartsTheRestFromTheClock() {
        let session = Self.session(ProgramCatalog.fundamentals)
        session.finishRound(inGroup: 2)

        #expect(session.groups[2]?.tracker?.completed == 1)
        #expect(session.groups[2]?.tracker?.rest == DateInterval(start: TestDate.reference, duration: 90))
        #expect(session.groups[1]?.tracker?.completed == 0)

        session.endRest(inGroup: 2)
        #expect(session.groups[2]?.tracker?.rest == nil)
    }

    @Test
    func roundsAreNotUnsavedChangesAndLoggingStaysPerExercise() async {
        let store = InMemoryWorkoutLogStore()
        let plan = ProgramPrescriber.plans(for: ProgramCatalog.fundamentals, pathStates: ProgramFixtures.newcomer,
                                           today: ProgramFixtures.today)[0]
        let session = QuickWorkoutViewModel(store: store, plan: plan, pathStates: ProgramFixtures.newcomer, logs: [])
        session.finishRound(inGroup: 1)
        #expect(!session.hasUnsavedChanges)

        await session.finish()
        let saved = store.load()
        #expect(saved.count == 6)
        #expect(Set(saved.map(\.exerciseID)).count == 6)
        #expect(saved.allSatisfy { $0.planID == plan.id })
    }

    @Test
    func anExerciseAddedDuringTheWorkoutIsASingle() {
        let session = Self.session(ProgramCatalog.fundamentals)
        let extra = ExerciseCatalog.exercise(withID: ExerciseCatalog.plankID)!
        session.addExercise(extra, sets: [LoggedSet(value: 30, measurement: .seconds)])

        #expect(session.blocks.map(\.kind) == [.group(1), .group(2), .group(3), .singles])
    }

    @Test
    func removingAPairsExercisesRemovesItsBlock() {
        let session = Self.session(ProgramCatalog.fundamentals)
        for item in session.blocks[0].items { session.remove(item) }
        #expect(session.blocks.map(\.kind) == [.group(2), .group(3)])
    }

    @Test
    func aFreeWorkoutHasNoGroups() {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        let pushUps = ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID)!
        session.addExercise(pushUps, sets: [LoggedSet(reps: 10)])
        #expect(session.groups.isEmpty)
        #expect(session.blocks.map(\.kind) == [.singles])
    }
}
