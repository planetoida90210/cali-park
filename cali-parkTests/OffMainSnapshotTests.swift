import Foundation
import Testing

@testable import cali_park

// MARK: - Fixtures
private enum Fixture {
    static let day = Date(timeIntervalSince1970: 1_790_000_000)

    static func pullUps(_ reps: [Int], date: Date = day) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, date: date, sets: reps.map { LoggedSet(reps: $0) })
    }

    static func dips(_ reps: [Int], date: Date = day) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, date: date, sets: reps.map { LoggedSet(reps: $0) })
    }
}

/// A clock a test moves by hand.
@MainActor
private final class ManualClock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

// MARK: - Progress

/// `ProgressService` computes its snapshot off the main actor after a change
/// and publishes the newest one; rewards and Home follow the published one.
@MainActor
@Suite("Progress is computed off the main actor, newest change first", .timeLimit(.minutes(1)))
struct OffMainProgressTests {
    @Test
    func theFirstSnapshotIsReadyAtLaunch() {
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [Fixture.pullUps([8, 8, 8])]))

        // No settling: the store is read before the first screen.
        #expect(stack.progress.isComputing == false)
        #expect(stack.progress.snapshot.pathStates[.pullUp]?.conqueredRungCount == 6)
    }

    @Test
    func theNewestOfTwoQuickChangesWins() async throws {
        let placementStore = InMemorySkillPlacementStore()
        let stack = TrainingStack(placementStore: placementStore)
        let before = stack.progress.computationCount

        // Two changes in one main-actor turn: the first computation is
        // superseded before it can publish.
        try placementStore.save(SkillPlacement(declaredRungByPath: [.pullUp: 2]))
        stack.progress.reloadPlacement()
        let newest = SkillPlacement(declaredRungByPath: [.pullUp: 7])
        try placementStore.save(newest)
        stack.progress.reloadPlacement()
        #expect(stack.progress.isComputing)

        await stack.settle()

        #expect(stack.progress.isComputing == false)
        #expect(stack.progress.snapshot.placement == newest)
        #expect(stack.progress.computationCount == before + 1)
    }

    @Test
    func twoQuickSavesAreBothInTheSnapshot() async throws {
        let stack = TrainingStack()

        async let first: Void = stack.journal.log(Fixture.pullUps([8, 8, 8]))
        async let second: Void = stack.journal.log(Fixture.dips([10, 10, 10]))
        _ = try await (first, second)
        await stack.settle()

        let fresh = ProgressionEngine.snapshot(
            logs: stack.journal.entries, placement: nil,
            calendar: TestCalendar.utc, today: TestDate.reference)
        #expect(stack.journal.entries.count == 2)
        #expect(stack.progress.snapshot.pathStates == fresh.pathStates)
        #expect(stack.progress.snapshot.level == fresh.level)
    }
}

// MARK: - Rewards

@MainActor
@Suite("Celebrations follow the published snapshot, once each", .timeLimit(.minutes(1)))
struct OffMainRewardTests {
    /// The celebrations each save queues when it is evaluated on its own.
    private func celebrationsOneAtATime() async throws -> (first: Int, second: Int) {
        let stack = TrainingStack()
        try await stack.journal.log(Fixture.pullUps([8, 8, 8]))
        await stack.settle()
        let first = stack.drainCelebrations()
        try await stack.journal.log(Fixture.dips([10, 10, 10]))
        await stack.settle()
        return (first, stack.drainCelebrations())
    }

    @Test
    func twoQuickSavesCelebrateEveryRungOnce() async throws {
        let expected = try await celebrationsOneAtATime()
        #expect(expected.first > 0)
        #expect(expected.second > 0)

        let stack = TrainingStack()
        let startXP = stack.progress.snapshot.level.totalXP
        async let first: Void = stack.journal.log(Fixture.pullUps([8, 8, 8]))
        async let second: Void = stack.journal.log(Fixture.dips([10, 10, 10]))
        _ = try await (first, second)
        await stack.settle()

        // The batch's last overlay carries what both saves gained.
        #expect(stack.rewards.batchXPGain == stack.progress.snapshot.level.totalXP - startXP)
        #expect(stack.rewards.xpToastAmount == nil)
        #expect(stack.drainCelebrations() == expected.first + expected.second)

        // Nothing is owed any more, whatever refreshes later.
        stack.rewards.refresh()
        await stack.settle()
        #expect(stack.rewards.currentCelebration == nil)
        #expect(stack.rewards.xpToastAmount == nil)
    }

    @Test
    func aSaveIsCelebratedOnceItsSnapshotLands() async throws {
        let stack = TrainingStack()

        try await stack.journal.log(Fixture.pullUps([8, 8, 8]))
        await stack.settle()

        #expect(stack.rewards.currentCelebration == .rungs(0...5, on: .pullUp))
        let shown = stack.drainCelebrations()
        #expect(shown > 0)

        // A later change with nothing new conquered toasts its XP only.
        try await stack.journal.log(Fixture.pullUps([1]))
        await stack.settle()
        #expect(stack.rewards.currentCelebration == nil)
        #expect(stack.rewards.xpToastAmount == ProgressionEngine.xpPerRep)
    }

    /// The weekly goal is evaluated on the spot, progress a moment later: the
    /// goal card waits so it never shows before the rungs of the same save.
    @Test
    func aMetGoalWaitsWhileProgressIsComputing() async throws {
        typealias F = WeeklyGoalFixtures
        let now = F.day(3)
        let placementStore = InMemorySkillPlacementStore()
        let journal = TrainingJournal(store: InMemoryWorkoutLogStore(initial: F.trained(week: 0, days: [0, 1])))
        let progress = ProgressService(
            journal: journal, placementStore: placementStore,
            calendar: F.calendar, clock: { now })
        let goals = WeeklyGoalService(
            journal: journal, store: InMemoryWeeklyGoalStore(),
            planService: .testing(InMemoryWorkoutPlanStore()),
            calendar: F.calendar, clock: { now })
        let rewards = RewardCenter(progress: progress, store: InMemorySkillProgressStore(), goals: goals)

        // The third training day meets the default goal.
        try await journal.log(F.entry(at: now))
        await progress.settle()
        #expect(rewards.current?.presentation.eyebrow == "CEL TYGODNIOWY WYKONANY")

        try placementStore.save(SkillPlacement(declaredRungByPath: [.core: 1]))
        progress.reloadPlacement()
        #expect(rewards.current == nil)

        await progress.settle()
        #expect(rewards.current?.presentation.eyebrow == "CEL TYGODNIOWY WYKONANY")
    }
}

// MARK: - Home

@MainActor
@Suite("Home is computed off the main actor and keeps the last snapshot meanwhile", .timeLimit(.minutes(1)))
struct OffMainHomeTests {
    private static let calendar = TestCalendar.utc
    /// 2026-11-04T08:00:00Z.
    private static let today = Date(timeIntervalSince1970: 1_793_779_200)

    private static func plan(_ name: String, _ schedule: WorkoutSchedule) -> WorkoutPlan {
        WorkoutPlan(
            name: name, exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
            schedule: schedule, createdAt: today - 7 * 86_400)
    }

    @Test
    func homeShowsALogOnceItsSnapshotLands() async throws {
        let yesterday = Fixture.pullUps([8, 8, 8], date: Self.today - 86_400)
        let home = HomeHarness(
            logStore: InMemoryWorkoutLogStore(initial: [yesterday]),
            calendar: Self.calendar, clock: { Self.today })
        let dashboard = home.dashboard
        // The first read is computed on the spot: Home never starts empty.
        #expect(dashboard.latestWorkout?.entries.map(\.id) == [yesterday.id])
        #expect(dashboard.streak.current == 1)

        let todays = Fixture.dips([10], date: Self.today)
        try await home.journal.log(todays)

        // Until the new snapshot lands, Home keeps showing the last one.
        #expect(dashboard.latestWorkout?.entries.map(\.id) == [yesterday.id])

        await home.settle()
        #expect(dashboard.latestWorkout?.entries.map(\.id) == [todays.id])
        #expect(dashboard.streak.current == 2)
        #expect(dashboard.heroState().isCompletedToday)
        #expect(dashboard.achievementsSummary.level == home.progress.snapshot.level.level)
        #expect(dashboard.snapshotComputationCount == 2)
    }

    @Test
    func theNewestPlansWin() async throws {
        let planStore = InMemoryWorkoutPlanStore()
        let home = HomeHarness(planStore: planStore, calendar: Self.calendar, clock: { Self.today })
        let dashboard = home.dashboard
        _ = dashboard.snapshot
        let before = dashboard.snapshotComputationCount

        // Two plan changes, each read by a render, before either lands.
        try planStore.save(Self.plan("Pierwszy", .weekly([.friday])))
        dashboard.reload()
        _ = dashboard.snapshot
        let newest = Self.plan("Codziennie", .weekly(Set(Weekday.allCases)))
        try planStore.save(newest)
        dashboard.reload()
        _ = dashboard.snapshot

        await dashboard.settle()

        guard case .planToday(let plan, _, _) = dashboard.heroState() else {
            Issue.record("Expected today's plan, got \(dashboard.heroState())")
            return
        }
        #expect(plan.id == newest.id)
        #expect(dashboard.snapshotComputationCount == before + 1)
    }

    /// Inputs that go back to the ones on screen drop the computation in
    /// flight, so an older result never replaces the current one.
    @Test
    func goingBackToTheShownInputsDropsTheComputationInFlight() async throws {
        let clock = ManualClock(Self.today)
        let home = HomeHarness(
            logStore: InMemoryWorkoutLogStore(initial: [Fixture.pullUps([8], date: Self.today)]),
            calendar: Self.calendar, clock: { clock.now })
        let dashboard = home.dashboard
        let shown = dashboard.snapshot

        clock.now = Self.today + 86_400
        dashboard.reload()
        _ = dashboard.snapshot // starts computing tomorrow
        clock.now = Self.today
        dashboard.reload()
        _ = dashboard.snapshot // back to today

        await dashboard.settle()
        #expect(dashboard.snapshot == shown)
        #expect(dashboard.heroState().isCompletedToday)
        #expect(dashboard.snapshotComputationCount == 1)
    }
}
