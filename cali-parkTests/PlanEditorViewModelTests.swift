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
        PlanEditorViewModel(plan: nil, store: store, calendar: Fixtures.calendar)
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
        #expect(editor.schedule == .once(Fixtures.day(5)))
    }

    @Test
    func saveUpsertsWithStablePlanID() throws {
        let store = InMemoryWorkoutPlanStore()
        let editor = newEditor(store: store)
        editor.name = "Pull"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.toggle(.monday)

        editor.save()
        #expect(editor.didSave)
        #expect(store.load().count == 1)

        let savedID = try #require(store.load().first?.id)

        // Editing the same plan and saving again updates in place (no duplicate).
        let again = PlanEditorViewModel(plan: store.load().first, store: store, calendar: Fixtures.calendar)
        again.name = "Pull day"
        again.save()

        #expect(store.load().count == 1)
        #expect(store.load().first?.id == savedID)
        #expect(store.load().first?.name == "Pull day")
    }

    @Test
    func saveWithoutRequiredFieldsIsANoOp() {
        let store = InMemoryWorkoutPlanStore()
        let editor = newEditor(store: store)
        editor.name = "Incomplete"
        // No exercises yet.
        editor.save()

        #expect(!editor.didSave)
        #expect(store.load().isEmpty)
    }

    @Test
    func saveFailureSurfacesError() {
        let editor = PlanEditorViewModel(plan: nil, store: FailingWorkoutPlanStore(), calendar: Fixtures.calendar)
        editor.name = "Pull"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.toggle(.monday)

        editor.save()

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
        let editor = PlanEditorViewModel(plan: plan, store: InMemoryWorkoutPlanStore(), calendar: Fixtures.calendar)

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

        let viewModel = WorkoutPlansViewModel(store: store)

        #expect(viewModel.plans.map(\.name) == ["New", "Old"])
    }

    @Test
    func deleteRemovesFromStoreAndList() throws {
        let plan = WorkoutPlan(name: "Pull", schedule: .weekly([.monday]))
        let store = InMemoryWorkoutPlanStore(initial: [plan])
        let viewModel = WorkoutPlansViewModel(store: store)

        viewModel.delete(plan)

        #expect(viewModel.plans.isEmpty)
        #expect(store.load().isEmpty)
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
        #expect(WorkoutScheduleFormatter.summary(.everyNDays(1, from: Fixtures.day(0))) == "Codziennie")
        #expect(WorkoutScheduleFormatter.summary(.everyNDays(3, from: Fixtures.day(0))) == "Co 3 dni")
    }

    @Test
    func onceWithoutDateIsADraft() {
        #expect(WorkoutScheduleFormatter.summary(.once(nil)) == "Bez terminu")
    }
}
