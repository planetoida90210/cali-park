//
//  PlanEditorViewModelTests.swift
//  cali-parkTests
//
//  Sprint 7 — planner UI: editor validation, exercise editing, schedule
//  selection, upsert on save, and the plans-list view model + schedule text.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Shared stubs

/// Always fails — verifies error surfacing (pattern: `FailingWorkoutLogStore`).
private struct FailingWorkoutPlanStore: WorkoutPlanStoring {
    struct SampleError: Error {}
    func load() -> [WorkoutPlan] { [] }
    func save(_ plan: WorkoutPlan) throws { throw SampleError() }
    func delete(id: UUID) throws { throw SampleError() }
}

private enum Fixtures {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static func day(_ n: Int) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400)
    }
}

// MARK: - PlanEditorViewModel

@MainActor
struct PlanEditorViewModelTests {
    private func newEditor(store: WorkoutPlanStoring = InMemoryWorkoutPlanStore()) -> PlanEditorViewModel {
        PlanEditorViewModel(plan: nil, service: .testing(store), calendar: Fixtures.calendar)
    }

    @Test
    func newPlanCannotBeSavedUntilComplete() {
        let editor = newEditor()
        #expect(!editor.canSave)

        editor.name = "  "
        editor.addExercise(ExerciseCatalog.all[0])
        editor.toggle(.monday)
        // Whitespace-only name still blocks saving.
        #expect(!editor.canSave)

        editor.name = "Pull day"
        #expect(editor.canSave)
    }

    @Test
    func weeklyModeNeedsAtLeastOneDay() {
        let editor = newEditor()
        editor.name = "Pull"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.scheduleMode = .weekly
        #expect(!editor.canSave)

        editor.toggle(.monday)
        #expect(editor.canSave)
    }

    @Test
    func otherModesDoNotRequireWeekdays() {
        let editor = newEditor()
        editor.name = "Full body"
        editor.addExercise(ExerciseCatalog.all[0])

        editor.scheduleMode = .everyNDays
        #expect(editor.canSave)

        editor.scheduleMode = .once
        #expect(editor.canSave)
    }

    @Test
    func addExerciseIgnoresDuplicates() {
        let editor = newEditor()
        editor.addExercise(ExerciseCatalog.all[0])
        editor.addExercise(ExerciseCatalog.all[0])
        editor.addExercise(ExerciseCatalog.all[1])

        #expect(editor.exercises.count == 2)
    }

    @Test
    func removeDropsThePlannedExercise() {
        let editor = newEditor()
        editor.addExercise(ExerciseCatalog.all[0])
        editor.addExercise(ExerciseCatalog.all[1])

        editor.remove(editor.exercises[0])
        #expect(editor.exercises.count == 1)

        editor.remove(atOffsets: IndexSet(integer: 0))
        #expect(editor.exercises.isEmpty)
    }

    @Test
    func toggleWeekdayAddsAndRemoves() {
        let editor = newEditor()
        editor.toggle(.monday)
        editor.toggle(.thursday)
        #expect(editor.selectedWeekdays == [.monday, .thursday])

        editor.toggle(.monday)
        #expect(editor.selectedWeekdays == [.thursday])
    }

    @Test
    func scheduleReflectsSelectedMode() {
        let editor = newEditor()

        editor.scheduleMode = .weekly
        editor.toggle(.monday)
        #expect(editor.schedule == .weekly([.monday]))

        editor.scheduleMode = .everyNDays
        editor.interval = 3
        if case .everyNDays(let n, _) = editor.schedule {
            #expect(n == 3)
        } else {
            Issue.record("Expected everyNDays schedule")
        }

        editor.scheduleMode = .once
        editor.onceDate = Fixtures.day(5)
        #expect(editor.schedule == .once(Fixtures.day(5), in: Fixtures.calendar))
    }

    @Test
    func saveUpsertsWithStablePlanID() async throws {
        let store = InMemoryWorkoutPlanStore()
        let editor = newEditor(store: store)
        editor.name = "Pull"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.toggle(.monday)

        await editor.save()
        #expect(editor.didSave)
        #expect(store.load().count == 1)

        let savedID = try #require(store.load().first?.id)

        // Editing the same plan and saving again updates in place (no duplicate).
        let again = PlanEditorViewModel(plan: store.load().first, service: .testing(store), calendar: Fixtures.calendar)
        again.name = "Pull day"
        await again.save()

        #expect(store.load().count == 1)
        #expect(store.load().first?.id == savedID)
        #expect(store.load().first?.name == "Pull day")
    }

    @Test
    func saveWithoutRequiredFieldsIsANoOp() async {
        let store = InMemoryWorkoutPlanStore()
        let editor = newEditor(store: store)
        editor.name = "Incomplete"
        // No exercises yet.
        await editor.save()

        #expect(!editor.didSave)
        #expect(store.load().isEmpty)
    }

    @Test
    func saveFailureSurfacesError() async {
        let editor = PlanEditorViewModel(plan: nil, service: .testing(FailingWorkoutPlanStore()), calendar: Fixtures.calendar)
        editor.name = "Pull"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.toggle(.monday)

        await editor.save()

        #expect(editor.errorMessage != nil)
        #expect(!editor.didSave)
    }

    @Test
    func editingExistingPlanPreloadsFields() {
        let plan = WorkoutPlan(
            name: "Legs",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.squatsID)],
            schedule: .weekly([.tuesday, .friday])
        )
        let editor = PlanEditorViewModel(plan: plan, service: .testing(InMemoryWorkoutPlanStore()), calendar: Fixtures.calendar)

        #expect(editor.name == "Legs")
        #expect(editor.exercises.count == 1)
        #expect(editor.scheduleMode == .weekly)
        #expect(editor.selectedWeekdays == [.tuesday, .friday])
    }
}

// MARK: - WorkoutPlansViewModel

@MainActor
struct WorkoutPlansViewModelTests {
    @Test
    func loadsNewestFirst() {
        let older = WorkoutPlan(name: "Old", schedule: .weekly([.monday]), createdAt: Fixtures.day(1))
        let newer = WorkoutPlan(name: "New", schedule: .weekly([.tuesday]), createdAt: Fixtures.day(9))
        let store = InMemoryWorkoutPlanStore(initial: [older, newer])

        let viewModel = WorkoutPlansViewModel(service: .testing(store))
        viewModel.reload()

        #expect(viewModel.plans.map(\.name) == ["New", "Old"])
    }

    /// D-6: the view builds the view model in its `init`, which SwiftUI may
    /// run many times, so the init must not read the store; appear does.
    @Test
    func initReadsNothingUntilReload() {
        let store = InMemoryWorkoutPlanStore(initial: [WorkoutPlan(name: "Plan", schedule: .weekly([.monday]))])

        let viewModel = WorkoutPlansViewModel(service: .testing(store))
        #expect(viewModel.plans.isEmpty)

        viewModel.reload()
        #expect(viewModel.plans.map(\.name) == ["Plan"])
    }

    @Test
    func deleteRemovesFromStoreAndList() async throws {
        let plan = WorkoutPlan(name: "Pull", schedule: .weekly([.monday]))
        let store = InMemoryWorkoutPlanStore(initial: [plan])
        let viewModel = WorkoutPlansViewModel(service: .testing(store))

        await viewModel.delete(plan)

        #expect(viewModel.plans.isEmpty)
        #expect(store.load().isEmpty)
    }
}

// MARK: - Expired one-off plans in the list

@MainActor
struct ExpiredPlanListTests {
    private static let polish = Locale(identifier: "pl_PL")

    @Test
    func pastOneOffPlanReadsAsPassed() throws {
        let day = try #require(CalendarDay(year: 2026, month: 11, day: 3))
        let today = try #require(CalendarDay(year: 2026, month: 11, day: 4)).startDate(in: Fixtures.calendar)

        #expect(WorkoutSchedule.once(day).isExpired(asOf: today, calendar: Fixtures.calendar))
        let line = WorkoutScheduleFormatter.listSummary(.once(day), asOf: today, calendar: Fixtures.calendar, locale: Self.polish)
        #expect(line == "Minął · 3 lis")
    }

    @Test
    func todaysOneOffPlanAndRecurringPlansAreNotPassed() throws {
        let today = try #require(CalendarDay(year: 2026, month: 11, day: 4))
        let now = today.startDate(in: Fixtures.calendar) + 23 * 3_600

        #expect(!WorkoutSchedule.once(today).isExpired(asOf: now, calendar: Fixtures.calendar))
        #expect(!WorkoutSchedule.once(nil).isExpired(asOf: now, calendar: Fixtures.calendar))
        #expect(!WorkoutSchedule.weekly([.monday]).isExpired(asOf: now, calendar: Fixtures.calendar))
        let line = WorkoutScheduleFormatter.listSummary(.once(today), asOf: now, calendar: Fixtures.calendar, locale: Self.polish)
        #expect(line == "Jednorazowo · 4 lis")
    }

    @Test
    func plansListMarksThePassedPlan() async throws {
        let past = try #require(CalendarDay(year: 2026, month: 11, day: 3))
        let now = try #require(CalendarDay(year: 2026, month: 11, day: 4)).startDate(in: Fixtures.calendar)
        let plan = WorkoutPlan(name: "Raz", schedule: .once(past))
        let viewModel = WorkoutPlansViewModel(service: .testing(InMemoryWorkoutPlanStore(initial: [plan])),
                                              calendar: Fixtures.calendar, now: { now })

        #expect(viewModel.scheduleSummary(for: plan).hasPrefix("Minął · 3 "))
    }
}

// MARK: - WorkoutScheduleFormatter

struct WorkoutScheduleFormatterTests {
    private var mondayFirst: Calendar {
        var calendar = Fixtures.calendar
        calendar.firstWeekday = 2
        return calendar
    }

    @Test
    func weeklyListsDaysInLocaleOrder() {
        let summary = WorkoutScheduleFormatter.summary(.weekly([.thursday, .monday]), calendar: mondayFirst)
        #expect(summary == "Co tydzień · Pon, Czw")
    }

    @Test
    func emptyWeeklyHasNoDays() {
        #expect(WorkoutScheduleFormatter.summary(.weekly([]), calendar: mondayFirst) == "Co tydzień")
    }

    @Test
    func intervalReadsAsEveryNDaysOrDaily() {
        #expect(WorkoutScheduleFormatter.summary(.everyNDays(1, from: Fixtures.day(0), in: Fixtures.calendar)) == "Codziennie")
        #expect(WorkoutScheduleFormatter.summary(.everyNDays(3, from: Fixtures.day(0), in: Fixtures.calendar)) == "Co 3 dni")
    }

    @Test
    func onceWithoutDateIsADraft() {
        #expect(WorkoutScheduleFormatter.summary(.once(nil)) == "Bez terminu")
    }

    // G-3: dates follow the Polish locale, not English ("20 Jul", "Saturday").

    private static let polish = Locale(identifier: "pl_PL")

    @Test
    func onceShowsPolishMonth() throws {
        let day = try #require(CalendarDay(year: 2026, month: 7, day: 20))
        let summary = WorkoutScheduleFormatter.summary(.once(day), calendar: Fixtures.calendar, locale: Self.polish)
        #expect(summary == "Jednorazowo · 20 lip")
    }

    @Test
    func dayLabelUsesPolishWeekdayAndMonth() throws {
        let monday = try #require(CalendarDay(year: 2026, month: 11, day: 2)).startDate(in: Fixtures.calendar)
        let saturday = try #require(Fixtures.calendar.date(byAdding: .day, value: 5, to: monday))
        let later = try #require(Fixtures.calendar.date(byAdding: .day, value: 18, to: monday))

        let weekday = WorkoutScheduleFormatter.dayLabel(saturday, asOf: monday, calendar: Fixtures.calendar, locale: Self.polish)
        let date = WorkoutScheduleFormatter.dayLabel(later, asOf: monday, calendar: Fixtures.calendar, locale: Self.polish)

        #expect(weekday == "sobota")
        #expect(date == "20 lis")
    }
}
