//
//  WorkoutReminderTests.swift
//  cali-parkTests
//
//  Sprint 1 (Profil + powiadomienia) — reminder request building & scheduling.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum ReminderFixtures {
    /// UTC Gregorian calendar so weekday/day math never depends on the machine.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Midnight UTC of `1970-01-01 + n days` (epoch day 0 is a Thursday).
    static func day(_ n: Int) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400)
    }

    /// A moment on day `n` at the given hour (UTC).
    static func day(_ n: Int, hour: Int) -> Date {
        day(n).addingTimeInterval(Double(hour) * 3_600)
    }

    static let reminderAt1830 = DateComponents(hour: 18, minute: 30)

    static func plan(schedule: WorkoutSchedule,
                     reminderTime: DateComponents? = reminderAt1830,
                     isActive: Bool = true,
                     exercises: Int = 2,
                     name: String = "Pull") -> WorkoutPlan {
        let planned = (0..<exercises).map { _ in PlannedExercise(exerciseID: UUID()) }
        return WorkoutPlan(name: name,
                           exercises: planned,
                           schedule: schedule,
                           isActive: isActive,
                           createdAt: day(0),
                           reminderTime: reminderTime)
    }
}

// MARK: - Weekly

struct WorkoutReminderWeeklyTests {
    @Test
    func weeklyBuildsOneRepeatingRequestPerDay() {
        let plan = ReminderFixtures.plan(schedule: .weekly([.monday, .wednesday]))
        let requests = WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar)

        #expect(requests.count == 2)
        #expect(requests.allSatisfy(\.repeats))
        #expect(Set(requests.compactMap { $0.dateComponents.weekday }) == [Weekday.monday.rawValue, Weekday.wednesday.rawValue])
        #expect(requests.allSatisfy { $0.dateComponents.hour == 18 && $0.dateComponents.minute == 30 })
        #expect(requests.allSatisfy { $0.id.hasPrefix("plan-") && $0.id.contains("-wd") })
    }

    @Test
    func emptyWeeklySetProducesNothing() {
        let plan = ReminderFixtures.plan(schedule: .weekly([]))
        #expect(WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar).isEmpty)
    }
}

// MARK: - Guards

struct WorkoutReminderGuardTests {
    @Test
    func inactivePlanProducesNothing() {
        let plan = ReminderFixtures.plan(schedule: .weekly([.monday]), isActive: false)
        #expect(WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar).isEmpty)
    }

    @Test
    func planWithoutReminderTimeProducesNothing() {
        let plan = ReminderFixtures.plan(schedule: .weekly([.monday]), reminderTime: nil)
        #expect(WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar).isEmpty)
    }
}

// MARK: - One-off & interval

struct WorkoutReminderOneOffTests {
    @Test
    func futureOnceBuildsSingleDatedRequest() throws {
        let plan = ReminderFixtures.plan(schedule: .once(ReminderFixtures.day(10)))
        let requests = WorkoutReminderPlanner.requests(for: plan,
                                                       calendar: ReminderFixtures.calendar,
                                                       asOf: ReminderFixtures.day(5))
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(request.repeats == false)
        #expect(request.id.hasSuffix("-once"))
        #expect(request.dateComponents.day != nil && request.dateComponents.year != nil)
        let fireDate = try #require(ReminderFixtures.calendar.date(from: request.dateComponents))
        #expect(fireDate > ReminderFixtures.day(5))
    }

    @Test
    func pastOnceProducesNothing() {
        let plan = ReminderFixtures.plan(schedule: .once(ReminderFixtures.day(2)))
        let requests = WorkoutReminderPlanner.requests(for: plan,
                                                       calendar: ReminderFixtures.calendar,
                                                       asOf: ReminderFixtures.day(5))
        #expect(requests.isEmpty)
    }

    @Test
    func everyNDaysBuildsSingleFutureRequest() throws {
        let plan = ReminderFixtures.plan(schedule: .everyNDays(3, from: ReminderFixtures.day(0)))
        let requests = WorkoutReminderPlanner.requests(for: plan,
                                                       calendar: ReminderFixtures.calendar,
                                                       asOf: ReminderFixtures.day(1))
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(request.repeats == false)
        #expect(request.id.hasSuffix("-interval"))
    }

    /// When today's reminder time already passed, `everyNDays` skips to the
    /// next scheduled day rather than scheduling in the past.
    @Test
    func everyNDaysAdvancesWhenTodaysTimePassed() throws {
        // Anchor day 0, interval 3 → occurrences on days 0, 3, 6, 9…
        // Reference: day 6 at 20:00, reminder 18:30 → today's slot passed.
        let plan = ReminderFixtures.plan(schedule: .everyNDays(3, from: ReminderFixtures.day(0)))
        let requests = WorkoutReminderPlanner.requests(for: plan,
                                                       calendar: ReminderFixtures.calendar,
                                                       asOf: ReminderFixtures.day(6, hour: 20))
        let request = try #require(requests.first)
        let fireDate = try #require(ReminderFixtures.calendar.date(from: request.dateComponents))
        #expect(fireDate > ReminderFixtures.day(6, hour: 20))
    }
}

// MARK: - Content & stability

struct WorkoutReminderContentTests {
    @Test
    func titleAndBodyUsePlanNameAndPolishPlural() throws {
        let plan = ReminderFixtures.plan(schedule: .weekly([.monday]), exercises: 2, name: "Push")
        let request = try #require(WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar).first)
        #expect(request.title == "Push")
        #expect(request.body == "Czas na trening · 2 ćwiczenia")
    }

    @Test
    func identifiersAreStableAcrossBuilds() {
        let plan = ReminderFixtures.plan(schedule: .weekly([.monday, .friday]))
        let first = WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar).map(\.id)
        let second = WorkoutReminderPlanner.requests(for: plan, calendar: ReminderFixtures.calendar).map(\.id)
        #expect(first == second)
    }

    @Test
    func multiplePlansAggregate() {
        let plans = [
            ReminderFixtures.plan(schedule: .weekly([.monday])),
            ReminderFixtures.plan(schedule: .weekly([.tuesday, .thursday]))
        ]
        #expect(WorkoutReminderPlanner.requests(for: plans, calendar: ReminderFixtures.calendar).count == 3)
    }
}

// MARK: - InMemory scheduler

struct InMemoryReminderSchedulerTests {
    @Test
    func rescheduleRecordsBuiltRequests() async {
        let scheduler = InMemoryReminderScheduler(calendar: ReminderFixtures.calendar)
        let plan = ReminderFixtures.plan(schedule: .weekly([.monday, .wednesday]))

        await scheduler.reschedule(for: [plan])

        let scheduled = await scheduler.scheduledRequests
        let count = await scheduler.rescheduleCount
        #expect(scheduled.count == 2)
        #expect(count == 1)
    }

    @Test
    func requestAuthorizationGrantsWhenConfigured() async {
        let granting = InMemoryReminderScheduler(grantOnRequest: true)
        #expect(await granting.requestAuthorization() == true)

        let denying = InMemoryReminderScheduler(grantOnRequest: false)
        #expect(await denying.requestAuthorization() == false)
    }

    @Test
    func cancelAllClearsRequests() async {
        let scheduler = InMemoryReminderScheduler(calendar: ReminderFixtures.calendar)
        await scheduler.reschedule(for: [ReminderFixtures.plan(schedule: .weekly([.monday]))])
        await scheduler.cancelAll()
        #expect(await scheduler.scheduledRequests.isEmpty)
    }
}
