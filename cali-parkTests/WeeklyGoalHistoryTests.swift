//
//  WeeklyGoalHistoryTests.swift
//  cali-parkTests
//
//  Ticket 027: goal versions, the implicit default, pauses up to 90 days,
//  celebration marks, and the store (envelope, quarantine, roundtrip).
//

import Foundation
import Testing

@testable import cali_park

private typealias F = WeeklyGoalFixtures

// MARK: - Goal sets and defaults

struct WeeklyGoalSetTests {
    @Test(arguments: [(-2, 1), (0, 1), (1, 1), (3, 3), (5, 5), (7, 7), (9, 7)])
    func defaultFromProgramFrequencyIsClamped(requested: Int, expected: Int) {
        let goals = WeeklyGoal.defaultGoals(trainingDaysPerWeek: requested)
        #expect(goals == [WeeklyGoal(id: WeeklyGoal.defaultGoalID, metric: .trainingDays(days: expected))])
    }

    @Test
    func defaultIsThreeTrainingDays() {
        #expect(WeeklyGoal.defaultGoals.map(\.metric) == [.trainingDays(days: 3)])
    }

    @Test
    func validSetsHoldOneToThreeDistinctGoalsInRange() {
        let a = F.goal(.trainingDays(days: 3))
        let b = F.goal(.plannedWorkouts(target: .allScheduled))
        let c = F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 75))
        let d = F.goal(.plannedWorkouts(target: .count(workouts: 2)))

        #expect(WeeklyGoal.isValidSet([a]))
        #expect(WeeklyGoal.isValidSet([a, b, c]))
        #expect(WeeklyGoal.isValidSet([]) == false)
        #expect(WeeklyGoal.isValidSet([a, b, c, d]) == false)
        #expect(WeeklyGoal.isValidSet([a, a]) == false)
        #expect(WeeklyGoal.isValidSet([F.goal(.trainingDays(days: 0))]) == false)
        #expect(WeeklyGoal.isValidSet([F.goal(.trainingDays(days: 8))]) == false)
        #expect(WeeklyGoal.isValidSet([F.goal(.plannedWorkouts(target: .count(workouts: 0)))]) == false)
        #expect(
            WeeklyGoal.isValidSet([
                F.goal(
                    .exerciseVolume(
                        exerciseID: ExerciseCatalog.pullUpsID,
                        measurement: .reps, amount: 0))
            ]) == false)
    }

    @Test
    func versionWithoutGoalsDoesNotDecode() {
        let json = #"{"effectiveFrom":"2026-11-02T00:00:00Z","goals":[]}"#
        #expect(throws: DecodingError.self) {
            try JSONFileFormat.decoder.decode(WeeklyGoalVersion.self, from: Data(json.utf8))
        }
    }
}

// MARK: - Setting goals

struct WeeklyGoalVersionHistoryTests {
    private let five = [F.days(5)]

    /// The first save writes the implicit default down first, so the weeks
    /// earned under it keep counting.
    @Test
    func firstSaveKeepsTheDefaultHistory() throws {
        let firstWorkout = F.day(week: -4, 3)
        let history = try #require(
            WeeklyGoalHistory.empty.settingGoals(
                five, at: F.day(2), implicitStart: firstWorkout, calendar: F.calendar
            ))
        #expect(
            history.versions == [
                F.version(WeeklyGoal.defaultGoals, from: firstWorkout),
                F.version(five, from: F.day(2))
            ])
    }

    /// Saved in the same week the journal started, the new goals replace the
    /// default but keep its start, so the warm-up week stays where it was.
    @Test
    func firstSaveInTheFirstWeekKeepsTheWarmUpAnchor() throws {
        let history = try #require(
            WeeklyGoalHistory.empty.settingGoals(
                five, at: F.day(5), implicitStart: F.day(3), calendar: F.calendar
            ))
        #expect(history.versions == [F.version(five, from: F.day(3))])
    }

    @Test
    func editsInOneWeekReplaceEachOther() throws {
        let start = try #require(
            WeeklyGoalHistory.empty.settingGoals(
                [F.days(3)], at: F.day(week: -3), implicitStart: F.day(week: -3), calendar: F.calendar
            ))
        let first = try #require(start.settingGoals(five, at: F.day(1), implicitStart: .distantPast, calendar: F.calendar))
        let second = try #require(
            first.settingGoals(
                [F.days(6)], at: F.day(4), implicitStart: .distantPast,
                calendar: F.calendar))
        #expect(
            second.versions == [
                F.version([F.days(3)], from: F.day(week: -3)),
                F.version([F.days(6)], from: F.day(1))
            ])

        // Changing back to last week's goals leaves nothing to keep.
        let reverted = try #require(
            second.settingGoals(
                [F.days(3)], at: F.day(5), implicitStart: .distantPast,
                calendar: F.calendar))
        #expect(reverted.versions == [F.version([F.days(3)], from: F.day(week: -3))])
    }

    @Test
    func savingTheSameGoalsChangesNothing() throws {
        let history = WeeklyGoalHistory(versions: [F.version(five, from: F.day(week: -2))])
        #expect(history.settingGoals(five, at: F.day(1), implicitStart: .distantPast, calendar: F.calendar) == history)
    }

    @Test
    func invalidGoalsAreRejected() {
        let tooMany = (0..<4).map { _ in F.goal(.trainingDays(days: 2)) }
        #expect(WeeklyGoalHistory.empty.settingGoals([], at: F.day(1), implicitStart: F.day(1)) == nil)
        #expect(WeeklyGoalHistory.empty.settingGoals(tooMany, at: F.day(1), implicitStart: F.day(1)) == nil)
    }

    @Test
    func currentGoalsFallBackToTheDefault() {
        #expect(WeeklyGoalHistory.empty.currentGoals(at: F.day(1)) == WeeklyGoal.defaultGoals)
        let history = WeeklyGoalHistory(versions: [
            F.version([F.days(2)], from: F.day(week: -2)),
            F.version(five, from: F.day(1))
        ])
        #expect(history.currentGoals(at: F.day(2)) == five)
        #expect(history.currentGoals(at: F.day(week: -1)) == [F.days(2)])
    }
}

// MARK: - Pauses

struct WeeklyGoalPauseTests {
    private let id = UUID(uuidString: "11111111-2222-4333-8444-555555555555")!

    @Test
    func pauseStartsAtTheStartOfTodayAndEndsOnTheChosenDay() throws {
        let history = try #require(
            WeeklyGoalHistory.empty.startingPause(
                at: F.day(2, hour: 15), until: F.day(9, hour: 8), calendar: F.calendar, id: id
            ))
        #expect(history.pauses == [WeeklyGoalPause(id: id, start: F.day(2, hour: 0), plannedEnd: F.day(9, hour: 0))])
        #expect(history.activePause(at: F.day(8, hour: 23)) != nil)
        #expect(history.activePause(at: F.day(9, hour: 0)) == nil)
    }

    @Test(arguments: [(0, 1), (-5, 1), (90, 90), (91, 90), (400, 90)])
    func pauseLengthIsClampedToOneThroughNinetyDays(requestedDays: Int, expectedDays: Int) throws {
        let start = F.day(0, hour: 0)
        let end = try #require(F.calendar.date(byAdding: .day, value: requestedDays, to: start))
        let history = try #require(WeeklyGoalHistory.empty.startingPause(at: start, until: end, calendar: F.calendar))
        let pause = try #require(history.pauses.first)
        #expect(F.calendar.dateComponents([.day], from: pause.start, to: pause.plannedEnd).day == expectedDays)
    }

    @Test
    func onlyOnePauseAtATime() throws {
        let paused = try #require(
            WeeklyGoalHistory.empty.startingPause(
                at: F.day(0), until: F.day(14),
                calendar: F.calendar))
        #expect(paused.startingPause(at: F.day(3), until: F.day(20), calendar: F.calendar) == nil)

        let ended = try #require(paused.endingPause(at: F.day(4)))
        #expect(ended.activePause(at: F.day(4)) == nil)
        let again = try #require(ended.startingPause(at: F.day(5), until: F.day(8), calendar: F.calendar))
        #expect(again.pauses.count == 2)
        #expect(again.activePause(at: F.day(6)) == again.pauses.last)
    }

    @Test
    func endingEarlyKeepsThePausedDays() throws {
        let paused = try #require(
            WeeklyGoalHistory.empty.startingPause(
                at: F.day(0), until: F.day(30),
                calendar: F.calendar, id: id))
        let ended = try #require(paused.endingPause(at: F.day(3)))
        let pause = try #require(ended.pauses.first)
        #expect(pause.endedAt == F.day(3))
        #expect(pause.end == F.day(3))
        #expect(pause.overlaps(F.week(0)))
        #expect(pause.overlaps(F.week(1)) == false)
    }

    @Test
    func endingAtTheVeryStartRemovesThePause() throws {
        let paused = try #require(
            WeeklyGoalHistory.empty.startingPause(
                at: F.day(0, hour: 0), until: F.day(7),
                calendar: F.calendar))
        #expect(paused.endingPause(at: F.day(0, hour: 0))?.pauses.isEmpty == true)
    }

    @Test
    func endingWithoutAnActivePauseDoesNothing() {
        #expect(WeeklyGoalHistory.empty.endingPause(at: F.day(1)) == nil)
    }
}

// MARK: - Celebration marks

struct WeeklyGoalCelebrationMarkTests {
    @Test
    func marksAreKeptForEightWeeks() {
        let goalID = WeeklyGoal.defaultGoalID
        var history = WeeklyGoalHistory.empty
        for week in -10...0 {
            history = history.markingCelebrated(goalID: goalID, weekStart: F.week(week).start, calendar: F.calendar)
        }
        #expect(history.celebrated.count == 9) // weeks -8 … 0
        #expect(history.hasCelebrated(goalID: goalID, weekStart: F.week(-8).start))
        #expect(history.hasCelebrated(goalID: goalID, weekStart: F.week(-9).start) == false)
        #expect(history.hasCelebrated(goalID: UUID(), weekStart: F.week(0).start) == false)
    }
}

// MARK: - Store

@Suite(.temporaryDirectories)
struct WeeklyGoalStoreTests {
    private func makeDirectory() throws -> URL {
        let directory = try TemporaryDirectory.make("WeeklyGoalStoreTests")
        return directory
    }

    /// Whole-second dates, every metric kind, a pause and a celebration mark.
    private var sample: WeeklyGoalHistory {
        WeeklyGoalHistory(
            versions: [
                F.version(WeeklyGoal.defaultGoals, from: F.date(2026, 10, 1, 7, 30, 5)),
                F.version(
                    [
                        F.goal(
                            .plannedWorkouts(target: .allScheduled),
                            id: UUID(uuidString: "A1A1A1A1-0000-4000-8000-000000000001")!),
                        F.goal(
                            .plannedWorkouts(target: .count(workouts: 4)),
                            id: UUID(uuidString: "A1A1A1A1-0000-4000-8000-000000000002")!),
                        F.goal(
                            .exerciseVolume(exerciseID: ExerciseCatalog.lSitID, measurement: .seconds, amount: 180),
                            id: UUID(uuidString: "A1A1A1A1-0000-4000-8000-000000000003")!)
                    ], from: F.date(2026, 11, 4, 18, 2, 41))
            ],
            pauses: [
                WeeklyGoalPause(
                    id: UUID(uuidString: "B2B2B2B2-0000-4000-8000-000000000001")!,
                    start: F.date(2026, 10, 12, 0), plannedEnd: F.date(2026, 10, 19, 0),
                    endedAt: F.date(2026, 10, 15, 9, 12, 33))
            ],
            celebrated: [WeeklyGoalCelebration(weekStart: F.date(2026, 10, 26, 0), goalID: WeeklyGoal.defaultGoalID)]
        )
    }

    @Test
    func roundtripsThroughTheFileInTheEnvelope() throws {
        let directory = try makeDirectory()
        let store = FileWeeklyGoalStore(directory: directory)
        #expect(try store.load() == nil)

        try store.save(sample)
        #expect(try FileWeeklyGoalStore(directory: directory).load() == sample)

        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: directory.appending(path: "weekly-goal.json")))
        let top = try #require(object as? [String: Any])
        #expect(top["schemaVersion"] as? Int == 1)
        #expect(top["payload"] != nil)
    }

    @Test
    func unreadableFileThrowsIsQuarantinedAndBlocksWrites() throws {
        let directory = try makeDirectory()
        let url = directory.appending(path: "weekly-goal.json")
        try Data("{ not json".utf8).write(to: url)
        let store = FileWeeklyGoalStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.save(.empty) }
        #expect(try Data(contentsOf: url) == Data("{ not json".utf8))
        let copies = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("weekly-goal.corrupt-") }
        #expect(copies.count == 1)
    }

    @Test
    func inMemoryStoreCountsSaves() throws {
        let store = InMemoryWeeklyGoalStore()
        #expect(store.load() == nil)
        try store.save(sample)
        #expect(store.load() == sample)
        #expect(store.saveCount == 1)
    }
}
