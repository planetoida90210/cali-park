//
//  ReminderSchedulerTests.swift
//  cali-parkTests
//
//  B-7: the reminder scheduler respects the 64-pending cap (soonest first),
//  diffs instead of wiping, never interleaves two reschedules, and reports
//  failures instead of swallowing them.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum Fixtures {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Epoch day `n` at midnight UTC. Day 0 is a Thursday.
    static func day(_ n: Int, hour: Int = 0) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400 + Double(hour) * 3_600)
    }

    static let now = day(0, hour: 9) // Thursday 09:00

    static func plan(_ name: String,
                     schedule: WorkoutSchedule,
                     hour: Int = 18) -> WorkoutPlan {
        WorkoutPlan(name: name,
                    exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)],
                    schedule: schedule,
                    createdAt: day(-10),
                    reminderTime: DateComponents(hour: hour, minute: 0))
    }

    static func scheduler(center: FakeNotificationCenter) -> NotificationCenterReminderScheduler {
        NotificationCenterReminderScheduler(center: center, calendar: calendar, clock: { now })
    }
}

// MARK: - FakeNotificationCenter

/// Records pending requests and every call, and yields inside each call so an
/// unserialized scheduler would interleave two reschedules.
private actor FakeNotificationCenter: UserNotificationCentering {
    private(set) var pending: [String: WorkoutReminderRequest] = [:]
    /// Other features' requests, which the scheduler must never touch.
    private(set) var foreignIDs: Set<String> = []
    private(set) var log: [String] = []
    private var status: ReminderAuthorizationStatus
    private let failingIDs: Set<String>
    private let authorizationFails: Bool

    init(status: ReminderAuthorizationStatus = .authorized,
         failingIDs: Set<String> = [],
         authorizationFails: Bool = false) {
        self.status = status
        self.failingIDs = failingIDs
        self.authorizationFails = authorizationFails
    }

    func seed(_ requests: [WorkoutReminderRequest], foreign: Set<String> = []) {
        for request in requests { pending[request.id] = request }
        foreignIDs = foreign
    }

    var ownedIDs: Set<String> { Set(pending.keys) }

    func authorizationStatus() async -> ReminderAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
        struct Failure: Error {}
        if authorizationFails { throw Failure() }
        return status.isAuthorized
    }

    func pendingRequestIDs() async -> [String] {
        log.append("pending")
        for _ in 0..<5 { await Task.yield() }
        return Array(pending.keys) + foreignIDs
    }

    func add(_ request: WorkoutReminderRequest) async throws {
        struct Failure: Error {}
        await Task.yield()
        if failingIDs.contains(request.id) { throw Failure() }
        log.append("add \(request.planID)")
        pending[request.id] = request
    }

    func removePendingRequests(withIDs ids: [String]) async {
        log.append("remove")
        for id in ids {
            pending[id] = nil
            foreignIDs.remove(id)
        }
    }
}

// MARK: - Planner cap

struct ReminderPlannerCapTests {
    @Test
    func capKeepsTheSoonestReminders() {
        // From Thursday 09:00: Friday fires in 1 day, the one-off on Saturday
        // in 2, Monday in 4.
        let monday = Fixtures.plan("Mon", schedule: .weekly([.monday]))
        let friday = Fixtures.plan("Fri", schedule: .weekly([.friday]))
        let saturday = Fixtures.plan("Sat", schedule: .once(Fixtures.day(2)))

        let requests = WorkoutReminderPlanner.requests(for: [monday, friday, saturday],
                                                       calendar: Fixtures.calendar,
                                                       asOf: Fixtures.now,
                                                       limit: 2)

        #expect(requests.map(\.planID) == [friday.id, saturday.id])
    }

    @Test
    func neverExceedsTheSystemLimit() {
        // 10 plans × 7 weekdays = 70 repeating reminders, over iOS's 64.
        let plans = (0..<10).map { Fixtures.plan("P\($0)", schedule: .weekly(Set(Weekday.allCases)), hour: 6 + $0) }

        let requests = WorkoutReminderPlanner.requests(for: plans, calendar: Fixtures.calendar, asOf: Fixtures.now)

        #expect(WorkoutReminderPlanner.pendingLimit == 64)
        #expect(requests.count == 64)
        #expect(Set(requests.map(\.id)).count == 64)
    }

    @Test
    func intervalRemindersShareTheBudgetWithWeeklyOnes() {
        // A daily interval plan alone would fill all 64 slots; the weekend
        // reminders still get every weekend within the covered stretch.
        let daily = Fixtures.plan("Daily", schedule: .everyNDays(1, from: Fixtures.day(0)))
        let weekly = Fixtures.plan("Weekly", schedule: .weekly([.saturday, .sunday]), hour: 7)

        let requests = WorkoutReminderPlanner.requests(for: [daily, weekly], calendar: Fixtures.calendar, asOf: Fixtures.now)

        // Days 0–49 hold 50 daily reminders and 14 weekend ones (7 weekends,
        // the first on days 2 and 3).
        #expect(requests.count == 64)
        #expect(requests.filter { $0.planID == weekly.id }.count == 14)
        #expect(requests.filter { $0.planID == daily.id }.count == 50)
    }

    /// Several plans of every type: the capped set is exactly every plan's
    /// occurrences up to one shared date, so no plan starves another.
    @Test
    func capCoversEveryPlanUpToTheSameDate() throws {
        let plans = [
            Fixtures.plan("Daily", schedule: .everyNDays(1, from: Fixtures.day(0)), hour: 20),
            Fixtures.plan("Every3", schedule: .everyNDays(3, from: Fixtures.day(1)), hour: 7),
            Fixtures.plan("MonWedFri", schedule: .weekly([.monday, .wednesday, .friday])),
            Fixtures.plan("Sunday", schedule: .weekly([.sunday]), hour: 10),
            Fixtures.plan("Once", schedule: .once(Fixtures.day(5)))
        ]

        let capped = WorkoutReminderPlanner.requests(for: plans, calendar: Fixtures.calendar, asOf: Fixtures.now)
        let uncapped = WorkoutReminderPlanner.requests(for: plans, calendar: Fixtures.calendar, asOf: Fixtures.now, limit: 1_000)

        #expect(capped.count == 64)
        #expect(Set(capped.map(\.planID)) == Set(plans.map(\.id)))
        let horizon = try #require(capped.last.flatMap { Fixtures.calendar.date(from: $0.dateComponents) })
        let dueByHorizon = uncapped.filter { Fixtures.calendar.date(from: $0.dateComponents)! <= horizon }
        #expect(capped == dueByHorizon)
    }

    @Test
    func weeklyRemindersAreDatedForEachUpcomingWeekday() throws {
        let plan = Fixtures.plan("Push", schedule: .weekly([.monday, .thursday]))

        let requests = WorkoutReminderPlanner.requests(for: plan, calendar: Fixtures.calendar, asOf: Fixtures.now)

        // Thursday 18:00 is still ahead of Thursday 09:00, so it fires first.
        let fireDates = try requests.prefix(4).map { try #require(Fixtures.calendar.date(from: $0.dateComponents)) }
        #expect(fireDates == [0, 4, 7, 11].map { Fixtures.day($0, hour: 18) })
        #expect(requests.count == WorkoutReminderPlanner.pendingLimit)
        #expect(requests.allSatisfy { $0.dateComponents.hour == 18 && $0.dateComponents.day != nil && $0.id.contains("-on-") })
    }
}

// MARK: - Scheduler

struct NotificationCenterReminderSchedulerTests {
    @Test
    func rescheduleRemovesOnlyStaleOwnedRequests() async throws {
        let center = FakeNotificationCenter()
        let kept = Fixtures.plan("Kept", schedule: .weekly([.friday]))
        let deleted = Fixtures.plan("Deleted", schedule: .weekly([.monday]))
        await center.seed(WorkoutReminderPlanner.requests(for: [kept, deleted], calendar: Fixtures.calendar, asOf: Fixtures.now),
                          foreign: ["other-feature"])

        try await Fixtures.scheduler(center: center).reschedule(for: [kept])

        let pending = await center.pending
        #expect(Set(pending.values.map(\.planID)) == [kept.id])
        #expect(await center.foreignIDs == ["other-feature"])
    }

    @Test
    func editedTimeReplacesTheRequestInPlace() async throws {
        let center = FakeNotificationCenter()
        var plan = Fixtures.plan("Push", schedule: .weekly([.friday]))
        let scheduler = Fixtures.scheduler(center: center)
        try await scheduler.reschedule(for: [plan])

        plan.reminderTime = DateComponents(hour: 7, minute: 45)
        try await scheduler.reschedule(for: [plan])

        // Same days, so the same ids: every request is replaced, none added.
        let pending = await center.pending
        #expect(pending.count == WorkoutReminderPlanner.pendingLimit)
        #expect(pending.values.allSatisfy { $0.dateComponents.hour == 7 && $0.dateComponents.minute == 45 })
    }

    @Test
    func withoutPermissionNothingIsAddedButStaleRequestsGo() async throws {
        let center = FakeNotificationCenter(status: .denied)
        let old = Fixtures.plan("Old", schedule: .weekly([.monday]))
        await center.seed(WorkoutReminderPlanner.requests(for: old, calendar: Fixtures.calendar, asOf: Fixtures.now))

        try await Fixtures.scheduler(center: center).reschedule(for: [Fixtures.plan("New", schedule: .weekly([.friday]))])

        #expect(await center.pending.isEmpty)
    }

    @Test
    func failedAddsAreReportedAndTheRestStillScheduled() async throws {
        let failing = Fixtures.plan("Failing", schedule: .weekly([.friday]))
        let fine = Fixtures.plan("Fine", schedule: .weekly([.monday]))
        let failingID = try #require(WorkoutReminderPlanner.requests(for: failing, calendar: Fixtures.calendar, asOf: Fixtures.now).first?.id)
        let center = FakeNotificationCenter(failingIDs: [failingID])

        await #expect(throws: ReminderSchedulingError(failedRequestIDs: [failingID])) {
            try await Fixtures.scheduler(center: center).reschedule(for: [failing, fine])
        }
        let pending = await center.pending
        #expect(pending[failingID] == nil)
        #expect(pending.count == WorkoutReminderPlanner.pendingLimit - 1)
        #expect(Set(pending.values.map(\.planID)) == [failing.id, fine.id])
    }

    @Test
    func overlappingReschedulesNeverInterleave() async throws {
        let center = FakeNotificationCenter()
        let scheduler = Fixtures.scheduler(center: center)
        let first = Fixtures.plan("First", schedule: .weekly([.monday, .tuesday, .wednesday]))
        let second = Fixtures.plan("Second", schedule: .weekly([.friday, .saturday]))

        async let a: Void = scheduler.reschedule(for: [first])
        async let b: Void = scheduler.reschedule(for: [second])
        _ = try await (a, b)

        // Each run is "pending, (remove), adds" for one plan only.
        let runs = await center.log.split(separator: "pending").map { Set($0.filter { $0.hasPrefix("add") }) }
        #expect(runs.count == 2)
        #expect(runs.allSatisfy { $0.count == 1 })

        // The final state is one plan's full set, never a mix of both.
        let planIDs = Set(await center.pending.values.map(\.planID))
        #expect(planIDs == [first.id] || planIDs == [second.id])
    }

    /// Before dated reminders, weekly plans had one repeating request per
    /// weekday (`plan-<uuid>-wd<N>`). The first sync after the update must
    /// remove them, or they would keep firing on done days.
    @Test(arguments: [ReminderAuthorizationStatus.authorized, .denied])
    func firstSyncRemovesLegacyRepeatingRequests(status: ReminderAuthorizationStatus) async throws {
        let plan = Fixtures.plan("Push", schedule: .weekly([.monday, .thursday]))
        let legacy = [Weekday.monday, .thursday].map { weekday in
            WorkoutReminderRequest(id: "plan-\(plan.id.uuidString)-wd\(weekday.rawValue)",
                                   planID: plan.id,
                                   title: plan.name,
                                   body: "",
                                   dateComponents: DateComponents(hour: 18, minute: 0, weekday: weekday.rawValue))
        }
        let center = FakeNotificationCenter(status: status)
        await center.seed(legacy, foreign: ["other-feature"])

        try await Fixtures.scheduler(center: center).reschedule(for: [plan])

        let ids = await center.ownedIDs
        #expect(ids.isDisjoint(with: legacy.map(\.id)))
        #expect(ids.allSatisfy { $0.contains("-on-") })
        #expect(ids.count == (status.isAuthorized ? WorkoutReminderPlanner.pendingLimit : 0))
        #expect(await center.foreignIDs == ["other-feature"])
    }

    /// Finishing today's plan and syncing drops today's pending reminder.
    @Test
    func doneTodayRemovesTodaysPendingReminder() async throws {
        let center = FakeNotificationCenter()
        let scheduler = Fixtures.scheduler(center: center)
        let plan = Fixtures.plan("Push", schedule: .weekly([.thursday]))
        try await scheduler.reschedule(for: [plan])
        let todayID = "plan-\(plan.id.uuidString)-on-1970-01-01"
        #expect(await center.pending[todayID] != nil)

        let done = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                   date: Fixtures.day(0, hour: 8),
                                   sets: [LoggedSet(reps: 5)],
                                   planID: plan.id)
        try await scheduler.reschedule(for: [plan], entries: [done])

        let pending = await center.pending
        #expect(pending[todayID] == nil)
        #expect(pending.count == WorkoutReminderPlanner.pendingLimit)
    }

    @Test
    func failedAuthorizationRequestCountsAsDenied() async {
        let scheduler = Fixtures.scheduler(center: FakeNotificationCenter(authorizationFails: true))

        #expect(await scheduler.requestAuthorization() == false)
    }
}
