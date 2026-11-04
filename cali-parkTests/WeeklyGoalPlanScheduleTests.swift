//
//  WeeklyGoalPlanScheduleTests.swift
//  cali-parkTests
//
//  "Wszystkie zaplanowane" judges a closed week by the plans as they were
//  scheduled that week (`PlanScheduleRecord`), not by today's plans.
//

import Foundation
import Testing

@testable import cali_park

private typealias F = WeeklyGoalFixtures

private enum ScheduleFixture {
    static let allScheduled = F.goal(
        .plannedWorkouts(target: .allScheduled),
        id: UUID(uuidString: "D0000000-0000-4000-8000-0000000000A1")!)
    static let versions = [F.version([allScheduled], from: F.day(week: -6, hour: 0))]

    /// Monday, Wednesday, Friday since week -6.
    static let threeDays = WorkoutPlan(
        id: UUID(uuidString: "D0000000-0000-4000-8000-0000000000B1")!,
        name: "Trzy dni", schedule: .weekly([.monday, .wednesday, .friday]),
        createdAt: F.day(week: -6, hour: 0))

    /// The same plan, moved to every day this week.
    static var everyDay: WorkoutPlan {
        var plan = threeDays
        plan.schedule = .weekly(Set(Weekday.allCases))
        return plan
    }

    /// The plan done on Monday, Wednesday and Friday of `week`.
    static func doneMondayWednesdayFriday(week: Int) -> [WorkoutLogEntry] {
        [0, 2, 4].map { F.entry(at: F.day(week: week, $0), plan: threeDays) }
    }
}

// MARK: - Recording

@Suite("The weekly goal records the plans' schedules, at most once a week")
struct PlanScheduleRecordingTests {
    private typealias S = ScheduleFixture

    @Test
    func theFirstRecordKeepsTheActivePlansOnly() throws {
        let paused = WorkoutPlan(name: "Wyłączony", schedule: .weekly([.sunday]), isActive: false)

        let history = try #require(
            WeeklyGoalHistory.empty.recordingPlans(
                [S.threeDays, paused], at: F.day(1),
                calendar: F.calendar))
        #expect(history.planSchedules == [PlanScheduleRecord(effectiveFrom: F.day(1), plans: [ScheduledPlan(S.threeDays)])])
    }

    @Test
    func noPlansAndNoRecordWritesNothing() {
        #expect(WeeklyGoalHistory.empty.recordingPlans([], at: F.day(1), calendar: F.calendar) == nil)
    }

    @Test
    func unchangedPlansWriteNothing() throws {
        let history = try #require(
            WeeklyGoalHistory.empty.recordingPlans(
                [S.threeDays], at: F.day(week: -1),
                calendar: F.calendar))
        var renamed = S.threeDays
        renamed.name = "Nowa nazwa"
        renamed.exercises = [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)]
        #expect(history.recordingPlans([renamed], at: F.day(1), calendar: F.calendar) == nil)
    }

    @Test
    func aChangeInALaterWeekAddsARecord() throws {
        let first = try #require(
            WeeklyGoalHistory.empty.recordingPlans(
                [S.threeDays], at: F.day(week: -1),
                calendar: F.calendar))
        let second = try #require(first.recordingPlans([S.everyDay], at: F.day(1), calendar: F.calendar))

        #expect(second.planSchedules.map(\.effectiveFrom) == [F.day(week: -1), F.day(1)])
        #expect(second.planSchedules.last?.plans == [ScheduledPlan(S.everyDay)])
    }

    @Test
    func changesInTheSameWeekReplaceItsRecord() throws {
        let earlier = try #require(
            WeeklyGoalHistory.empty.recordingPlans(
                [S.threeDays], at: F.day(week: -1),
                calendar: F.calendar))
        let monday = try #require(earlier.recordingPlans([S.everyDay], at: F.day(0), calendar: F.calendar))
        let tuesday = try #require(monday.recordingPlans([], at: F.day(1), calendar: F.calendar))

        #expect(tuesday.planSchedules.count == 2)
        #expect(tuesday.planSchedules.last == PlanScheduleRecord(effectiveFrom: F.day(0), plans: []))
    }

    @Test
    func changingBackWithinTheWeekDropsItsRecord() throws {
        let earlier = try #require(
            WeeklyGoalHistory.empty.recordingPlans(
                [S.threeDays], at: F.day(week: -1),
                calendar: F.calendar))
        let changed = try #require(earlier.recordingPlans([S.everyDay], at: F.day(0), calendar: F.calendar))
        let back = try #require(changed.recordingPlans([S.threeDays], at: F.day(2), calendar: F.calendar))

        #expect(back == earlier)
    }
}

// MARK: - Judging closed weeks

@Suite("A closed week counts the plans it had")
struct ClosedWeekPlansTests {
    private typealias S = ScheduleFixture

    private static func verdict(
        _ week: Int, plans: [WorkoutPlan], records: [PlanScheduleRecord],
        entries: [WorkoutLogEntry]
    ) -> WeeklyGoalWeek? {
        WeeklyGoalEvaluator.evaluate(
            week: F.week(week), versions: S.versions, pauses: [], entries: entries,
            plans: plans, planSchedules: records, calendar: F.calendar, asOf: F.day(1))
    }

    @Test
    func aScheduleChangedThisWeekDoesNotRewriteLastWeek() {
        let records = [
            PlanScheduleRecord(effectiveFrom: F.day(week: -3), activePlansOf: [S.threeDays]),
            PlanScheduleRecord(effectiveFrom: F.day(0), activePlansOf: [S.everyDay])
        ]
        let entries = S.doneMondayWednesdayFriday(week: -1)

        let lastWeek = Self.verdict(-1, plans: [S.everyDay], records: records, entries: entries)
        #expect(lastWeek?.primary.target == 3)
        #expect(lastWeek?.status == .met)

        // Without records, today's plans judge it: 7 scheduled, 3 done.
        let legacy = Self.verdict(-1, plans: [S.everyDay], records: [], entries: entries)
        #expect(legacy?.primary.target == 7)
        #expect(legacy?.status == .missed)
    }

    @Test
    func aDeletedPlanStillCountsInTheWeeksItWasScheduled() {
        let records = [
            PlanScheduleRecord(effectiveFrom: F.day(week: -3), activePlansOf: [S.threeDays]),
            PlanScheduleRecord(effectiveFrom: F.day(0), activePlansOf: [])
        ]
        let entries = [F.entry(at: F.day(week: -1, 0), plan: S.threeDays)]

        let lastWeek = Self.verdict(-1, plans: [], records: records, entries: entries)
        #expect(lastWeek?.primary.target == 3)
        #expect(lastWeek?.primary.value == 1)
        #expect(lastWeek?.status == .missed)
    }

    @Test
    func aWeekBeforeEveryRecordUsesTheEarliestOne() {
        let records = [PlanScheduleRecord(effectiveFrom: F.day(week: -1, 3), activePlansOf: [S.threeDays])]
        let entries = S.doneMondayWednesdayFriday(week: -2)

        #expect(Self.verdict(-2, plans: [S.everyDay], records: records, entries: entries)?.status == .met)
    }

    @Test
    func theRunningWeekUsesTodaysPlans() {
        let records = [PlanScheduleRecord(effectiveFrom: F.day(week: -3), activePlansOf: [S.threeDays])]
        let thisWeek = Self.verdict(0, plans: [S.everyDay], records: records, entries: [])
        #expect(thisWeek?.primary.target == 7)
        #expect(thisWeek?.status == .inProgress)
    }

    @Test
    func theStreakKeepsWeeksMetUnderTheOldSchedule() {
        let records = [
            PlanScheduleRecord(effectiveFrom: F.day(week: -3), activePlansOf: [S.threeDays]),
            PlanScheduleRecord(effectiveFrom: F.day(0), activePlansOf: [S.everyDay])
        ]
        let entries = S.doneMondayWednesdayFriday(week: -2) + S.doneMondayWednesdayFriday(week: -1)
        let history = WeeklyGoalHistory(versions: S.versions, planSchedules: records)

        let snapshot = WeeklyGoalEvaluator.snapshot(
            history: history, entries: entries, plans: [S.everyDay],
            calendar: F.calendar, asOf: F.day(1))
        #expect(snapshot.streak == 2)
        #expect(
            WeeklyGoalEvaluator.snapshot(
                history: WeeklyGoalHistory(versions: S.versions), entries: entries,
                plans: [S.everyDay], calendar: F.calendar, asOf: F.day(1)
            ).streak == 0)
    }
}

// MARK: - Service

@MainActor
@Suite("Saving or deleting a plan records the schedules with the goal", .timeLimit(.minutes(1)))
struct PlanScheduleServiceTests {
    private typealias S = ScheduleFixture

    @Test
    func aSavedPlanIsRecordedAndADeletedOneLeavesItsWeeks() async throws {
        var now = F.day(week: -1, 1)
        let goalStore = InMemoryWeeklyGoalStore(initial: WeeklyGoalHistory(versions: S.versions))
        let planService = WorkoutPlanService.testing(InMemoryWorkoutPlanStore())
        let goals = WeeklyGoalService(
            journal: TrainingJournal(store: InMemoryWorkoutLogStore()),
            store: goalStore, planService: planService,
            calendar: F.calendar, clock: { now })

        try await planService.save(S.threeDays)
        #expect(goalStore.load()?.planSchedules == [PlanScheduleRecord(effectiveFrom: now, activePlansOf: [S.threeDays])])

        now = F.day(1)
        try await planService.delete(id: S.threeDays.id)
        let records = try #require(goalStore.load()?.planSchedules)
        #expect(records.map(\.plans) == [[ScheduledPlan(S.threeDays)], []])
        #expect(goals.history?.planSchedules == records)
    }

    @Test
    func aStoreRefusingWritesKeepsTheGoalReadable() async throws {
        let goalStore = ReadOnlyWeeklyGoalStore(initial: WeeklyGoalHistory(versions: S.versions))
        let planService = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(initial: [S.threeDays]))
        let goals = WeeklyGoalService(
            journal: TrainingJournal(store: InMemoryWorkoutLogStore()),
            store: goalStore, planService: planService,
            calendar: F.calendar, clock: { F.day(1) })

        #expect(goals.snapshot != nil)
        #expect(goals.history?.planSchedules.isEmpty == true)
    }
}

// MARK: - File format

private final class FixtureToken {}

@Suite("Weekly goal files from before plan records still load", .temporaryDirectories)
struct WeeklyGoalGoldenFileTests {
    /// What `weekly-goal-v1.json` holds: the envelope written by the first
    /// weekly goal release, without `planSchedules`.
    private static let expected = WeeklyGoalHistory(
        versions: [
            WeeklyGoalVersion(effectiveFrom: StoreFixtures.october1, goals: WeeklyGoal.defaultGoals),
            WeeklyGoalVersion(
                effectiveFrom: TestDate.at(2026, 10, 12, 9),
                goals: [
                    WeeklyGoal(
                        id: UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!,
                        metric: .plannedWorkouts(target: .allScheduled)),
                    WeeklyGoal(
                        id: UUID(uuidString: "D0000000-0000-4000-8000-000000000002")!,
                        metric: .exerciseVolume(exerciseID: StoreFixtures.plankID, measurement: .seconds, amount: 180))
                ])
        ],
        pauses: [
            WeeklyGoalPause(
                id: UUID(uuidString: "D0000000-0000-4000-8000-000000000003")!,
                start: TestDate.at(2026, 10, 19, 0), plannedEnd: TestDate.at(2026, 10, 26, 0),
                endedAt: StoreFixtures.october2.addingTimeInterval(20 * 86_400))
        ],
        celebrated: [
            WeeklyGoalCelebration(
                weekStart: TestDate.at(2026, 10, 12, 0),
                goalID: UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!)
        ]
    )

    private static func installFixture(in directory: URL) throws {
        let source = try #require(Bundle(for: FixtureToken.self).url(forResource: "weekly-goal-v1", withExtension: "json"))
        try FileManager.default.copyItem(at: source, to: directory.appending(path: StoreFile.weeklyGoal.fileName))
    }

    @Test
    func theFirstReleaseFormatDecodesWithoutRecords() throws {
        let directory = try TemporaryDirectory.make("WeeklyGoalGoldenFileTests")
        try Self.installFixture(in: directory)

        let loaded = try FileWeeklyGoalStore(directory: directory).load()
        #expect(loaded == Self.expected)
        #expect(loaded?.planSchedules.isEmpty == true)
    }

    @Test
    func recordsRoundtripAndAnEmptyListIsNotWritten() throws {
        let directory = try TemporaryDirectory.make("WeeklyGoalGoldenFileTests")
        let store = FileWeeklyGoalStore(directory: directory)
        let fileURL = directory.appending(path: StoreFile.weeklyGoal.fileName)

        try store.save(Self.expected)
        let bare = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any]
        let payload = try #require(bare?["payload"] as? [String: Any])
        #expect(payload["planSchedules"] == nil)

        var withRecords = Self.expected
        withRecords.planSchedules = [
            PlanScheduleRecord(
                effectiveFrom: StoreFixtures.october1,
                activePlansOf: [ScheduleFixture.threeDays])
        ]
        try store.save(withRecords)
        #expect(try store.load() == withRecords)
    }
}
