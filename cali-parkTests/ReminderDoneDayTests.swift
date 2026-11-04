//
//  ReminderDoneDayTests.swift
//  cali-parkTests
//
//  Ticket 019 follow-up: no reminder on a day the plan is already done. The
//  planner skips done days, the service reads the log for it, every log write
//  re-syncs, and a background refresh keeps the dated reminders topped up.
//

import BackgroundTasks
import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum Fixtures {
    static let calendar = TestCalendar.utc

    /// Epoch day `n` at `hour` UTC. Day 0 is a Thursday.
    static func day(_ n: Int, hour: Int = 0) -> Date {
        TestDate.epochDay(n, hour: hour)
    }

    /// Thursday 09:00.
    static let now = day(0, hour: 9)

    static func plan(_ name: String = "Push",
                     schedule: WorkoutSchedule = .weekly([.thursday, .friday])) -> WorkoutPlan {
        WorkoutPlan(name: name,
                    exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
                    schedule: schedule,
                    createdAt: day(-10),
                    reminderTime: DateComponents(hour: 18, minute: 0))
    }

    static func entry(planID: UUID?, at date: Date = now) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, date: date, sets: [LoggedSet(reps: 10)], planID: planID)
    }

    static func requests(for plans: [WorkoutPlan],
                         entries: [WorkoutLogEntry],
                         limit: Int = WorkoutReminderPlanner.pendingLimit) -> [WorkoutReminderRequest] {
        WorkoutReminderPlanner.requests(for: plans, entries: entries, calendar: calendar, asOf: now, limit: limit)
    }

    static func fireDay(_ request: WorkoutReminderRequest) -> Int? {
        calendar.date(from: request.dateComponents).map { Int($0.timeIntervalSince1970 / 86_400) }
    }

    static func scheduler() -> InMemoryReminderScheduler {
        InMemoryReminderScheduler(status: .authorized, calendar: calendar, clock: { now })
    }
}

/// Counts calls from a `@Sendable` closure.
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    var count: Int { lock.withLock { value } }

    func increment() { lock.withLock { value += 1 } }
}

// MARK: - Planner

struct ReminderPlannerDoneDayTests {
    @Test
    func doneTodaySkipsTodaysReminderOnly() {
        let plan = Fixtures.plan()

        let requests = Fixtures.requests(for: [plan], entries: [Fixtures.entry(planID: plan.id)], limit: 3)

        // Thursday (day 0) is done; Friday, next Thursday and Friday remain.
        #expect(requests.compactMap(Fixtures.fireDay) == [1, 7, 8])
    }

    @Test
    func undoneTodayKeepsTodaysReminder() {
        let plan = Fixtures.plan()

        let requests = Fixtures.requests(for: [plan], entries: [], limit: 3)

        #expect(requests.compactMap(Fixtures.fireDay) == [0, 1, 7])
    }

    /// Only an entry on that calendar day carrying this plan's id counts,
    /// exactly as on Home (`PlanAgenda.isDone`).
    @Test(arguments: [
        ("no plan id", nil as Int?, 0),
        ("another plan", 1, 0),
        ("yesterday", 0, -1)
    ])
    func otherEntriesDoNotCountAsDone(_ label: String, otherPlan: Int?, dayOffset: Int) {
        let plan = Fixtures.plan()
        let planID: UUID? = switch otherPlan {
        case nil: nil
        case 0: plan.id
        default: UUID()
        }
        let entry = Fixtures.entry(planID: planID, at: Fixtures.day(dayOffset, hour: 12))

        let requests = Fixtures.requests(for: [plan], entries: [entry], limit: 1)

        #expect(requests.compactMap(Fixtures.fireDay) == [0], "\(label)")
    }

    /// An entry late on the day still counts for that day.
    @Test
    func entryJustBeforeMidnightCountsForThatDay() {
        let plan = Fixtures.plan(schedule: .weekly([.friday]))
        let lateThursday = Fixtures.day(1).addingTimeInterval(-60)
        let earlyFriday = Fixtures.day(1).addingTimeInterval(60)

        #expect(Fixtures.requests(for: [plan], entries: [Fixtures.entry(planID: plan.id, at: lateThursday)], limit: 1)
            .compactMap(Fixtures.fireDay) == [1])
        #expect(Fixtures.requests(for: [plan], entries: [Fixtures.entry(planID: plan.id, at: earlyFriday)], limit: 1)
            .compactMap(Fixtures.fireDay) == [8])
    }

    @Test
    func doneOneOffGetsNoReminder() {
        let plan = Fixtures.plan(schedule: .once(Fixtures.day(0), in: Fixtures.calendar))

        #expect(Fixtures.requests(for: [plan], entries: [Fixtures.entry(planID: plan.id)]).isEmpty)
    }

    @Test
    func doneIntervalDayIsSkipped() {
        let plan = Fixtures.plan(schedule: .everyNDays(2, from: Fixtures.day(0), in: Fixtures.calendar))

        let requests = Fixtures.requests(for: [plan], entries: [Fixtures.entry(planID: plan.id)], limit: 2)

        #expect(requests.compactMap(Fixtures.fireDay) == [2, 4])
    }

    /// A done plan doesn't touch another plan's reminder on the same day.
    @Test
    func doneDayIsPerPlan() {
        let done = Fixtures.plan("Done", schedule: .weekly([.thursday]))
        let open = Fixtures.plan("Open", schedule: .weekly([.thursday]))

        let requests = Fixtures.requests(for: [done, open], entries: [Fixtures.entry(planID: done.id)], limit: 3)

        #expect(requests.filter { $0.planID == open.id }.compactMap(Fixtures.fireDay) == [0, 7])
        #expect(requests.filter { $0.planID == done.id }.compactMap(Fixtures.fireDay) == [7])
    }
}

// MARK: - Service

@MainActor
struct WorkoutPlanServiceDoneDayTests {
    @Test
    func syncSkipsThePlanDoneToday() async {
        let plan = Fixtures.plan()
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(initial: [plan]),
                                                 logStore: InMemoryWorkoutLogStore(initial: [Fixtures.entry(planID: plan.id)]),
                                                 scheduler: scheduler)

        #expect(await service.syncReminders() == .synced)

        let days = await scheduler.scheduledRequests.compactMap(Fixtures.fireDay)
        #expect(days.first == 1)
        #expect(!days.contains(0))
    }

    /// Better a reminder too many than none.
    @Test
    func unreadableLogSchedulesAsIfNothingWereDone() async {
        let plan = Fixtures.plan()
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(initial: [plan]),
                                                 logStore: UnreadableWorkoutLogStore(),
                                                 scheduler: scheduler)

        #expect(await service.syncReminders() == .synced)

        #expect(await scheduler.scheduledRequests.compactMap(Fixtures.fireDay).first == 0)
    }

    @Test
    func everySyncRequestsTheNextBackgroundRefresh() async throws {
        let refresh = InMemoryReminderRefreshScheduler()
        let service = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(),
                                                 scheduler: Fixtures.scheduler(),
                                                 refreshScheduler: refresh)

        await service.syncReminders()
        try await service.save(Fixtures.plan())

        #expect(refresh.scheduleCount == 2)
    }

    /// Even a failed sync keeps the background top-ups going.
    @Test
    func failedSyncStillRequestsTheNextRefresh() async {
        struct Unreadable: Error {}
        struct UnreadablePlanStore: WorkoutPlanStoring {
            func load() throws -> [WorkoutPlan] { throw Unreadable() }
            func save(_ plan: WorkoutPlan) throws {}
            func delete(id: UUID) throws {}
        }
        let refresh = InMemoryReminderRefreshScheduler()
        let service = WorkoutPlanService.testing(UnreadablePlanStore(), refreshScheduler: refresh)

        #expect(await service.syncReminders() == .failed)
        #expect(refresh.scheduleCount == 1)
    }
}

// MARK: - Log writes re-sync

@MainActor
struct TrainingJournalChangeTests {
    @Test
    func everySuccessfulWriteNotifies() throws {
        let counter = CallCounter()
        let base = InMemoryWorkoutLogStore()
        let journal = TrainingJournal(store: base)
        journal.onChange { counter.increment() }
        let entry = Fixtures.entry(planID: nil)

        try journal.log(entry)
        try journal.logSession([Fixtures.entry(planID: nil), Fixtures.entry(planID: nil)])
        try journal.delete(ids: [entry.id])
        journal.reloadIfFailed()

        #expect(counter.count == 3)
        #expect(base.load().count == 2)
    }

    @Test
    func failedWritesDoNotNotify() {
        let counter = CallCounter()
        let journal = TrainingJournal(store: UnreadableWorkoutLogStore())
        journal.onChange { counter.increment() }

        #expect(throws: UnreadableWorkoutLogStore.Unreadable.self) { try journal.log(Fixtures.entry(planID: nil)) }
        #expect(throws: UnreadableWorkoutLogStore.Unreadable.self) { try journal.delete(ids: [UUID()]) }
        #expect(counter.count == 0)
    }
}

@MainActor
struct AppEnvironmentReminderSyncTests {
    /// Waits until the scheduler has run `count` reschedules (the journal
    /// starts the sync in its own task).
    private func waitForReschedules(_ scheduler: InMemoryReminderScheduler, count: Int) async throws {
        for _ in 0..<200 where await scheduler.rescheduleCount < count {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    /// Finishing today's plan from any screen cancels today's reminder.
    @Test
    func savingTodaysPlanWorkoutDropsTodaysReminder() async throws {
        let plan = Fixtures.plan()
        let scheduler = Fixtures.scheduler()
        let environment = AppEnvironment(favoriteParkStore: InMemoryFavoriteParkStore(),
                                         favoriteExerciseStore: InMemoryFavoriteExerciseStore(),
                                         workoutLogStore: InMemoryWorkoutLogStore(),
                                         workoutPlanStore: InMemoryWorkoutPlanStore(initial: [plan]),
                                         reminderScheduler: scheduler,
                                         reminderRefreshScheduler: InMemoryReminderRefreshScheduler(),
                                         placementStore: InMemorySkillPlacementStore(),
                                         skillProgressStore: InMemorySkillProgressStore(),
                                         weeklyGoalStore: InMemoryWeeklyGoalStore(),
                                         diagnostics: DiagnosticsService(store: InMemoryDiagnosticReportStore()),
                                         defaults: .throwaway())
        await environment.workoutPlanService.syncReminders()
        #expect(await scheduler.scheduledRequests.compactMap(Fixtures.fireDay).first == 0)

        // Every view model writes through this journal (SetPad, quick
        // workout, history, session detail, Home).
        try environment.journal.log(Fixtures.entry(planID: plan.id))

        try await waitForReschedules(scheduler, count: 2)
        #expect(await scheduler.rescheduleCount == 2)
        #expect(await scheduler.scheduledRequests.compactMap(Fixtures.fireDay).first == 1)
    }

    /// D-7: a sync takes the entries from the journal in memory; only the
    /// journal's own launch read touches the log store.
    @Test
    func syncReadsTheJournalNotTheLogFile() async throws {
        let plan = Fixtures.plan()
        let logStore = SpyWorkoutLogStore()
        let scheduler = Fixtures.scheduler()
        let environment = AppEnvironment(favoriteParkStore: InMemoryFavoriteParkStore(),
                                         favoriteExerciseStore: InMemoryFavoriteExerciseStore(),
                                         workoutLogStore: logStore,
                                         workoutPlanStore: InMemoryWorkoutPlanStore(initial: [plan]),
                                         reminderScheduler: scheduler,
                                         reminderRefreshScheduler: InMemoryReminderRefreshScheduler(),
                                         placementStore: InMemorySkillPlacementStore(),
                                         skillProgressStore: InMemorySkillProgressStore(),
                                         weeklyGoalStore: InMemoryWeeklyGoalStore(),
                                         diagnostics: DiagnosticsService(store: InMemoryDiagnosticReportStore()),
                                         defaults: .throwaway())
        try environment.journal.log(Fixtures.entry(planID: plan.id))
        await environment.workoutPlanService.syncReminders()

        #expect(logStore.loadCount == 1)
        // The entry logged a moment ago still counts: today is done.
        #expect(await scheduler.scheduledRequests.compactMap(Fixtures.fireDay).first == 1)
    }
}

// MARK: - Background refresh

struct AppRefreshSchedulerTests {
    @Test
    func refreshIsRequestedAboutADayLater() {
        let request = AppRefreshScheduler.request(after: Fixtures.now)

        #expect(request.identifier == AppRefreshScheduler.taskIdentifier)
        #expect(request.earliestBeginDate == Fixtures.now.addingTimeInterval(24 * 60 * 60))
    }

    /// iOS refuses to schedule an identifier missing from the Info.plist.
    @Test
    func infoPlistPermitsTheRefreshTask() {
        let identifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String]
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]

        #expect(identifiers?.contains(AppRefreshScheduler.taskIdentifier) == true)
        #expect(modes?.contains("fetch") == true)
    }
}
