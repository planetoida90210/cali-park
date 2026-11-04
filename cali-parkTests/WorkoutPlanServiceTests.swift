//
//  WorkoutPlanServiceTests.swift
//  cali-parkTests
//
//  Ticket 019: WorkoutPlanService owns plan save/delete and keeps reminders in
//  sync; the plan editor's reminder toggle asks for permission on first enable.
//

import Foundation
import Testing
@testable import cali_park

private enum Fixtures {
    static let calendar = TestCalendar.utc

    /// Thursday 1970-01-01, 09:00 UTC.
    static let now = Date(timeIntervalSince1970: 9 * 3_600)

    static func plan(_ name: String = "Push",
                     days: Set<Weekday> = [.monday, .friday],
                     reminder: DateComponents? = DateComponents(hour: 18, minute: 30)) -> WorkoutPlan {
        WorkoutPlan(name: name,
                    exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
                    schedule: .weekly(days),
                    createdAt: Date(timeIntervalSince1970: 0),
                    reminderTime: reminder)
    }

    static func scheduler(status: ReminderAuthorizationStatus = .authorized,
                          grantOnRequest: Bool = true,
                          failsToSchedule: Bool = false) -> InMemoryReminderScheduler {
        InMemoryReminderScheduler(status: status,
                                  grantOnRequest: grantOnRequest,
                                  failsToSchedule: failsToSchedule,
                                  calendar: calendar,
                                  clock: { now })
    }
}

/// A plan store whose file cannot be read.
private struct UnreadablePlanStore: WorkoutPlanStoring {
    struct Unreadable: Error {}
    func load() throws -> [WorkoutPlan] { throw Unreadable() }
    func save(_ plan: WorkoutPlan) throws {}
    func delete(id: UUID) throws {}
}

// MARK: - WorkoutPlanService

@MainActor
struct WorkoutPlanServiceTests {
    @Test
    func saveStoresThePlanAndSchedulesItsReminders() async throws {
        let store = InMemoryWorkoutPlanStore()
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(store, scheduler: scheduler)
        let plan = Fixtures.plan()

        let result = try await service.save(plan)

        #expect(result == .synced)
        #expect(store.load() == [plan])
        let scheduled = await scheduler.scheduledRequests
        #expect(scheduled.isEmpty == false)
        #expect(Set(scheduled.map(\.planID)) == [plan.id])
    }

    @Test
    func deleteCancelsThePlansReminders() async throws {
        let plan = Fixtures.plan()
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(initial: [plan]), scheduler: scheduler)
        await service.syncReminders()
        #expect(await scheduler.scheduledRequests.isEmpty == false)

        try await service.delete(id: plan.id)

        #expect(await scheduler.scheduledRequests.isEmpty)
    }

    @Test
    func reminderFailureIsReportedButThePlanIsSaved() async throws {
        let store = InMemoryWorkoutPlanStore()
        let service = WorkoutPlanService.testing(store, scheduler: Fixtures.scheduler(failsToSchedule: true))

        let result = try await service.save(Fixtures.plan())

        #expect(result == .failed)
        #expect(store.load().count == 1)
    }

    /// A broken plans file must never cancel every reminder.
    @Test
    func unreadablePlansLeaveRemindersAlone() async {
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(UnreadablePlanStore(), scheduler: scheduler)

        let result = await service.syncReminders()

        #expect(result == .failed)
        #expect(await scheduler.rescheduleCount == 0)
    }

    /// Each sync reads the store when it runs, so after two quick saves the
    /// reminders cover both plans.
    @Test
    func overlappingSavesEndWithEveryPlansReminders() async throws {
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(), scheduler: scheduler)
        let push = Fixtures.plan("Push", days: [.monday])
        let pull = Fixtures.plan("Pull", days: [.tuesday])

        async let first = service.save(push)
        async let second = service.save(pull)
        _ = try await (first, second)

        #expect(Set(await scheduler.scheduledRequests.map(\.planID)) == [push.id, pull.id])
    }
}

// MARK: - Plan editor reminder

@MainActor
struct PlanEditorReminderTests {
    private func editor(_ plan: WorkoutPlan? = nil,
                        store: InMemoryWorkoutPlanStore = InMemoryWorkoutPlanStore(),
                        scheduler: InMemoryReminderScheduler) -> PlanEditorViewModel {
        PlanEditorViewModel(plan: plan,
                            service: WorkoutPlanService.testing(store, scheduler: scheduler),
                            calendar: Fixtures.calendar,
                            now: Fixtures.now)
    }

    @Test
    func firstEnableAsksForPermissionAndTurnsOn() async {
        let scheduler = Fixtures.scheduler(status: .notDetermined, grantOnRequest: true)
        let editor = editor(scheduler: scheduler)

        await editor.setReminderEnabled(true)

        #expect(editor.reminderEnabled)
        #expect(editor.showsNotificationsDeniedHint == false)
        #expect(await scheduler.authorizationRequestCount == 1)
    }

    @Test
    func refusedPermissionTurnsTheToggleOffAndExplains() async {
        let editor = editor(scheduler: Fixtures.scheduler(status: .notDetermined, grantOnRequest: false))

        await editor.setReminderEnabled(true)

        #expect(editor.reminderEnabled == false)
        #expect(editor.showsNotificationsDeniedHint)
    }

    @Test
    func alreadyDeniedDoesNotPromptAgain() async {
        let scheduler = Fixtures.scheduler(status: .denied)
        let editor = editor(scheduler: scheduler)

        await editor.setReminderEnabled(true)

        #expect(editor.reminderEnabled == false)
        #expect(editor.showsNotificationsDeniedHint)
        #expect(await scheduler.authorizationRequestCount == 0)
    }

    @Test
    func alreadyAuthorizedDoesNotPrompt() async {
        let scheduler = Fixtures.scheduler(status: .authorized)
        let editor = editor(scheduler: scheduler)

        await editor.setReminderEnabled(true)

        #expect(editor.reminderEnabled)
        #expect(await scheduler.authorizationRequestCount == 0)
    }

    @Test
    func savedReminderTimeIsThePickedHourAndMinute() async throws {
        let store = InMemoryWorkoutPlanStore()
        let scheduler = Fixtures.scheduler()
        let editor = editor(store: store, scheduler: scheduler)
        editor.name = "Pull"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.toggle(.friday)
        await editor.setReminderEnabled(true)
        editor.reminderTime = try #require(Fixtures.calendar.date(bySettingHour: 7, minute: 15, second: 0, of: Fixtures.now))

        await editor.save()

        let saved = try #require(store.load().first)
        #expect(saved.reminderTime == DateComponents(hour: 7, minute: 15))
        #expect(editor.didSave)
        #expect(Set(await scheduler.scheduledRequests.map(\.dateComponents.hour)) == [7])
    }

    @Test
    func existingReminderOpensOnAndTurningItOffIsAnEdit() async throws {
        let plan = Fixtures.plan()
        let store = InMemoryWorkoutPlanStore(initial: [plan])
        let editor = editor(plan, store: store, scheduler: Fixtures.scheduler())
        #expect(editor.reminderEnabled)
        #expect(Fixtures.calendar.dateComponents([.hour, .minute], from: editor.reminderTime) == DateComponents(hour: 18, minute: 30))
        #expect(editor.hasUnsavedChanges == false)

        await editor.setReminderEnabled(false)
        #expect(editor.hasUnsavedChanges)
        await editor.save()

        #expect(try #require(store.load().first).reminderTime == nil)
    }

    @Test
    func changingOnlyTheTimeIsAnEdit() throws {
        let editor = editor(Fixtures.plan(), scheduler: Fixtures.scheduler())

        editor.reminderTime = try #require(Fixtures.calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Fixtures.now))

        #expect(editor.hasUnsavedChanges)
    }

    @Test
    func reminderFailureStillSavesAndWarns() async {
        let store = InMemoryWorkoutPlanStore()
        let editor = editor(Fixtures.plan(), store: store, scheduler: Fixtures.scheduler(failsToSchedule: true))

        await editor.save()

        #expect(editor.didSave)
        #expect(editor.errorMessage == "Plan zapisany, ale nie udało się ustawić przypomnienia.")
        #expect(store.load().count == 1)
    }

    @Test
    func openingAPlanWithAReminderShowsTheHintWhenNotificationsAreOff() async {
        let editor = editor(Fixtures.plan(), scheduler: Fixtures.scheduler(status: .denied))

        await editor.refreshNotificationPermission()

        #expect(editor.showsNotificationsDeniedHint)
        #expect(editor.reminderEnabled) // the user's choice is kept
    }
}

// MARK: - Plans list

@MainActor
struct WorkoutPlansListReminderTests {
    @Test
    func deletingAPlanRemovesItsReminders() async {
        let plan = Fixtures.plan()
        let scheduler = Fixtures.scheduler()
        let service = WorkoutPlanService.testing(InMemoryWorkoutPlanStore(initial: [plan]), scheduler: scheduler)
        await service.syncReminders()
        let viewModel = WorkoutPlansViewModel(service: service)

        await viewModel.delete(plan)

        #expect(viewModel.plans.isEmpty)
        #expect(await scheduler.scheduledRequests.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func rowShowsTheReminderTime() {
        let viewModel = WorkoutPlansViewModel(service: .testing(InMemoryWorkoutPlanStore()))

        #expect(viewModel.reminderSummary(for: Fixtures.plan(reminder: DateComponents(hour: 7, minute: 5))) == "07:05")
        #expect(viewModel.reminderSummary(for: Fixtures.plan(reminder: DateComponents(hour: 18, minute: 30))) == "18:30")
        #expect(viewModel.reminderSummary(for: Fixtures.plan(reminder: DateComponents(hour: 0, minute: 0))) == "00:00")
        #expect(viewModel.reminderSummary(for: Fixtures.plan(reminder: nil)) == nil)
    }
}
