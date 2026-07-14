//
//  WorkoutPlanTests.swift
//  cali-parkTests
//
//  Sprint 6 — planner data foundation: schedule math, store roundtrip, Codable.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum PlannerFixtures {
    /// UTC Gregorian calendar so weekday math never depends on the machine's
    /// locale or time zone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Midnight UTC of `1970-01-01 + n days`. Epoch day 0 is a Thursday, so
    /// offsets map to known weekdays: 0=Thu, 1=Fri, 2=Sat, 3=Sun, 4=Mon,
    /// 5=Tue, 6=Wed.
    static func day(_ n: Int) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400)
    }
}

// MARK: - Weekday

struct WeekdayTests {
    /// `rawValue` must equal `Calendar`'s `.weekday` for the same day, or the
    /// schedule math silently drifts.
    @Test(arguments: [
        (0, Weekday.thursday),
        (1, Weekday.friday),
        (2, Weekday.saturday),
        (3, Weekday.sunday),
        (4, Weekday.monday),
        (5, Weekday.tuesday),
        (6, Weekday.wednesday)
    ])
    func rawValueMatchesCalendar(offset: Int, expected: Weekday) {
        let weekdayIndex = PlannerFixtures.calendar.component(.weekday, from: PlannerFixtures.day(offset))
        #expect(Weekday(rawValue: weekdayIndex) == expected)
    }

    @Test
    func orderedFollowsFirstWeekday() {
        var mondayFirst = PlannerFixtures.calendar
        mondayFirst.firstWeekday = 2
        #expect(Weekday.ordered(for: mondayFirst).first == .monday)

        var sundayFirst = PlannerFixtures.calendar
        sundayFirst.firstWeekday = 1
        #expect(Weekday.ordered(for: sundayFirst).first == .sunday)
        #expect(Set(Weekday.ordered(for: mondayFirst)).count == 7)
    }
}

// MARK: - WorkoutSchedule.nextOccurrence

struct WorkoutScheduleTests {
    private let calendar = PlannerFixtures.calendar
    private func day(_ n: Int) -> Date { PlannerFixtures.day(n) }

    @Test(arguments: [
        // (referenceOffset, weekdays, expectedOffset) — reference day 0 is Thursday.
        (0, [Weekday.thursday], 0),          // matches today
        (0, [.friday], 1),                   // tomorrow
        (0, [.monday], 4),                   // next Monday
        (0, [.monday, .wednesday], 4),       // earliest of the two
        (1, [.thursday], 7),                 // from Friday, next Thursday is a week out
        (3, [.sunday], 3)                    // Sunday matches the reference day
    ])
    func weeklyPicksEarliestMatchingDay(referenceOffset: Int, weekdays: [Weekday], expectedOffset: Int) {
        let schedule = WorkoutSchedule.weekly(Set(weekdays))
        let next = schedule.nextOccurrence(onOrAfter: day(referenceOffset), calendar: calendar)
        #expect(next == day(expectedOffset))
    }

    @Test
    func weeklyIgnoresTimeOfDay() {
        let noon = calendar.date(byAdding: .hour, value: 12, to: day(0))!
        let schedule = WorkoutSchedule.weekly([.thursday])
        #expect(schedule.nextOccurrence(onOrAfter: noon, calendar: calendar) == day(0))
    }

    @Test
    func emptyWeeklyHasNoOccurrence() {
        #expect(WorkoutSchedule.weekly([]).nextOccurrence(onOrAfter: day(0), calendar: calendar) == nil)
    }

    @Test(arguments: [
        // (interval, anchorOffset, referenceOffset, expectedOffset)
        (7, 0, 0, 0),    // on the anchor day
        (7, 0, 1, 7),    // one day past → next multiple
        (7, 0, 7, 7),    // exactly one interval later
        (7, 0, 8, 14),   // just past → two intervals
        (3, 0, 2, 3),    // rounds up to the next multiple
        (3, 0, 3, 3),    // lands on a multiple
        (5, 10, 0, 10)   // anchor in the future → the anchor itself
    ])
    func everyNDaysAdvancesFromAnchor(interval: Int, anchorOffset: Int, referenceOffset: Int, expectedOffset: Int) {
        let schedule = WorkoutSchedule.everyNDays(interval, from: day(anchorOffset))
        let next = schedule.nextOccurrence(onOrAfter: day(referenceOffset), calendar: calendar)
        #expect(next == day(expectedOffset))
    }

    @Test
    func everyNDaysRejectsNonPositiveInterval() {
        #expect(WorkoutSchedule.everyNDays(0, from: day(0)).nextOccurrence(onOrAfter: day(0), calendar: calendar) == nil)
    }

    @Test
    func onceReturnsFutureDayAndDropsPast() {
        #expect(WorkoutSchedule.once(day(5)).nextOccurrence(onOrAfter: day(0), calendar: calendar) == day(5))
        #expect(WorkoutSchedule.once(day(0)).nextOccurrence(onOrAfter: day(5), calendar: calendar) == nil)
        #expect(WorkoutSchedule.once(nil).nextOccurrence(onOrAfter: day(0), calendar: calendar) == nil)
    }

    @Test
    func onceCountsTheSameDay() {
        let evening = calendar.date(byAdding: .hour, value: 20, to: day(3))!
        let morning = calendar.date(byAdding: .hour, value: 6, to: day(3))!
        #expect(WorkoutSchedule.once(evening).nextOccurrence(onOrAfter: morning, calendar: calendar) == day(3))
    }

    @Test
    func isRecurringReflectsCase() {
        #expect(WorkoutSchedule.once(nil).isRecurring == false)
        #expect(WorkoutSchedule.weekly([.monday]).isRecurring == true)
        #expect(WorkoutSchedule.everyNDays(2, from: PlannerFixtures.day(0)).isRecurring == true)
    }
}

// MARK: - WorkoutPlan

struct WorkoutPlanTests {
    private let calendar = PlannerFixtures.calendar

    @Test
    func inactivePlanHasNoOccurrence() {
        let plan = WorkoutPlan(
            name: "Pull",
            schedule: .weekly([.thursday]),
            isActive: false
        )
        #expect(plan.nextOccurrence(onOrAfter: PlannerFixtures.day(0), calendar: calendar) == nil)
    }

    @Test
    func activePlanForwardsToSchedule() {
        let plan = WorkoutPlan(name: "Pull", schedule: .weekly([.monday]))
        #expect(plan.nextOccurrence(onOrAfter: PlannerFixtures.day(0), calendar: calendar) == PlannerFixtures.day(4))
    }

    @Test
    func targetSetsSumsOnlyPrescribedValues() {
        let plan = WorkoutPlan(name: "Push", exercises: [
            PlannedExercise(exerciseID: UUID(), targetSets: 3),
            PlannedExercise(exerciseID: UUID()),
            PlannedExercise(exerciseID: UUID(), targetSets: 4)
        ])
        #expect(plan.exerciseCount == 3)
        #expect(plan.totalTargetSets == 7)
    }
}

// MARK: - Codable

struct WorkoutPlanCodableTests {
    @Test(arguments: [
        WorkoutSchedule.once(PlannerFixtures.day(5)),
        WorkoutSchedule.once(nil),
        WorkoutSchedule.weekly([.monday, .thursday]),
        WorkoutSchedule.everyNDays(3, from: PlannerFixtures.day(0))
    ])
    func planRoundtripsThroughJSON(schedule: WorkoutSchedule) throws {
        let plan = WorkoutPlan(
            name: "Trening",
            exercises: [PlannedExercise(exerciseID: UUID(), targetSets: 3, targetReps: 8)],
            schedule: schedule,
            createdAt: PlannerFixtures.day(2)
        )

        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(WorkoutPlan.self, from: data)
        #expect(decoded == plan)
    }
}

// MARK: - Store

struct WorkoutPlanStoreTests {
    @Test
    func inMemoryUpsertAndDelete() throws {
        let store = InMemoryWorkoutPlanStore()
        let plan = WorkoutPlan(name: "Pull", schedule: .weekly([.monday]))

        try store.save(plan)
        #expect(store.load().count == 1)

        // Saving the same id updates in place instead of appending.
        var edited = plan
        edited.name = "Pull day"
        try store.save(edited)
        #expect(store.load().count == 1)
        #expect(store.load().first?.name == "Pull day")

        try store.delete(id: plan.id)
        #expect(store.load().isEmpty)
    }

    @Test
    func fileStorePersistsAcrossInstances() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let plan = WorkoutPlan(
            name: "Full body",
            exercises: [PlannedExercise(exerciseID: UUID(), targetSets: 3)],
            schedule: .everyNDays(2, from: PlannerFixtures.day(0))
        )

        let writer = FileWorkoutPlanStore(directory: directory)
        try writer.save(plan)

        // A fresh instance reads what the first one wrote.
        let reader = FileWorkoutPlanStore(directory: directory)
        #expect(reader.load().count == 1)
        #expect(reader.load().first?.name == "Full body")

        try reader.delete(id: plan.id)
        #expect(FileWorkoutPlanStore(directory: directory).load().isEmpty)
    }

    @Test
    func loadIsEmptyWhenNoFileExists() {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        #expect(FileWorkoutPlanStore(directory: directory).load().isEmpty)
    }
}
