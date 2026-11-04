//
//  DiscardDraftTests.swift
//  cali-parkTests
//
//  Audit B-1 / E-3: a draft with unsaved changes (quick workout, plan editor,
//  SetPad) must block swipe-down and ask before "Anuluj" drops it, and a draft
//  with nothing entered must close without a question. The views read
//  `hasUnsavedChanges`, so these tests pin when it is true.
//  Audit B-6 / C-13: saving an edited plan keeps the fields the editor does
//  not edit.
//

import Foundation
import Testing
@testable import cali_park

private enum Fixtures {
    static let calendar = TestCalendar.utc

    /// 2026-11-03T12:00:00Z
    static let reference = Date(timeIntervalSince1970: 1_793_707_200)

    static var pullUps: Exercise { ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)! }
    static var pushUps: Exercise { ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID)! }

    /// A plan whose first exercise is prefilled from targets and whose second
    /// stays pending.
    static let plan = WorkoutPlan(
        name: "Push",
        exercises: [
            PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 10),
            PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)
        ],
        schedule: .weekly([.monday, .thursday]),
        isActive: false,
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        reminderTime: DateComponents(hour: 18, minute: 30)
    )
}

// MARK: - Quick workout

@MainActor
struct QuickWorkoutDiscardTests {
    @Test
    func emptyFreeWorkoutHasNothingToDiscard() {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        #expect(!session.hasUnsavedChanges)
    }

    /// A prefilled plan item counts as finishable, but the user has not
    /// entered anything yet, so leaving must not ask.
    @Test
    func untouchedPlanSessionHasNothingToDiscard() {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore(), plan: Fixtures.plan)
        #expect(session.canFinish)
        #expect(!session.hasUnsavedChanges)
    }

    @Test
    func addingAnExerciseIsAnUnsavedChange() {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        session.addExercise(Fixtures.pullUps, sets: [LoggedSet(reps: 6)])
        #expect(session.hasUnsavedChanges)
    }

    @Test
    func loggingSetsOnASeededItemIsAnUnsavedChange() throws {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore(), plan: Fixtures.plan)
        let pending = try #require(session.items.first { $0.isPending })
        session.updateSets(itemID: pending.id, sets: [LoggedSet(reps: 5)])
        #expect(session.hasUnsavedChanges)
    }

    @Test
    func removingASeededItemIsAnUnsavedChange() throws {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore(), plan: Fixtures.plan)
        session.remove(try #require(session.items.first))
        #expect(session.hasUnsavedChanges)
    }

    /// Adding then removing the only exercise leaves nothing to lose.
    @Test
    func undoingEveryChangeClearsTheFlag() throws {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        session.addExercise(Fixtures.pullUps, sets: [LoggedSet(reps: 6)])
        session.remove(try #require(session.items.first))
        #expect(!session.hasUnsavedChanges)
    }

    @Test
    func finishingClearsTheFlag() {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        session.addExercise(Fixtures.pullUps, sets: [LoggedSet(reps: 6)])
        session.finish()
        #expect(session.didFinish)
        #expect(!session.hasUnsavedChanges)
    }
}

// MARK: - SetPad

@MainActor
struct SetPadDiscardTests {
    private func logger() -> WorkoutLogViewModel {
        WorkoutLogViewModel(exercise: Fixtures.pullUps, store: InMemoryWorkoutLogStore())
    }

    @Test
    func emptyPadHasNothingToDiscard() {
        #expect(!logger().hasUnsavedChanges)
    }

    @Test
    func typedDigitIsAnUnsavedChange() {
        let pad = logger()
        pad.input.appendDigit(6)
        #expect(pad.hasUnsavedChanges)
    }

    @Test
    func clearingThePadClearsTheFlag() {
        let pad = logger()
        pad.input.appendDigit(6)
        pad.input.commitSet()
        pad.input.clear()
        #expect(!pad.hasUnsavedChanges)
    }

    @Test
    func savingClearsTheFlag() {
        let pad = logger()
        pad.input.appendDigit(8)
        pad.save()
        #expect(pad.didSave)
        #expect(!pad.hasUnsavedChanges)
    }

    /// C-12: a second tap on "Zapisz" while the sheet closes logs nothing.
    @Test
    func savingTwiceLogsOneEntry() {
        let store = InMemoryWorkoutLogStore()
        let pad = WorkoutLogViewModel(exercise: Fixtures.pullUps, store: store)
        pad.input.appendDigit(8)
        pad.save()
        pad.save()
        #expect(store.load().count == 1)
    }
}

// MARK: - Plan editor

@MainActor
struct PlanEditorDiscardTests {
    private func editor(_ plan: WorkoutPlan?, store: WorkoutPlanStoring = InMemoryWorkoutPlanStore()) -> PlanEditorViewModel {
        PlanEditorViewModel(plan: plan, service: .testing(store), calendar: Fixtures.calendar, now: Fixtures.reference)
    }

    @Test
    func freshEditorHasNothingToDiscard() {
        #expect(!editor(nil).hasUnsavedChanges)
        #expect(!editor(Fixtures.plan).hasUnsavedChanges)
    }

    /// `.once(nil)` opens as today's date in the picker; that is not an edit.
    @Test
    func undatedOncePlanOpensClean() {
        let plan = WorkoutPlan(name: "Kiedyś", exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)],
                               schedule: .once(nil))
        #expect(!editor(plan).hasUnsavedChanges)
    }

    @Test
    func whitespaceInTheNameIsNotAChange() {
        let edit = editor(nil)
        edit.name = "   "
        #expect(!edit.hasUnsavedChanges)
    }

    enum Edit: CaseIterable {
        case rename, addExercise, removeExercise, toggleWeekday, changeMode
    }

    @Test(arguments: Edit.allCases)
    func eachEditIsAnUnsavedChange(_ edit: Edit) throws {
        let editor = editor(Fixtures.plan)
        switch edit {
        case .rename:
            editor.name = "Push v2"
        case .addExercise:
            let planned = Set(Fixtures.plan.exercises.map(\.exerciseID))
            editor.addExercise(try #require(ExerciseCatalog.all.first { !planned.contains($0.id) }))
        case .removeExercise:
            editor.remove(atOffsets: [0])
        case .toggleWeekday:
            editor.toggle(.friday)
        case .changeMode:
            editor.scheduleMode = .everyNDays
        }
        #expect(editor.hasUnsavedChanges)
    }

    /// Switching modes and back yields the same schedule, so nothing is lost.
    @Test
    func switchingModeBackIsNotAChange() {
        let editor = editor(Fixtures.plan)
        editor.scheduleMode = .once
        editor.scheduleMode = .weekly
        #expect(!editor.hasUnsavedChanges)
    }

    @Test
    func savingClearsTheFlag() async {
        let editor = editor(Fixtures.plan)
        editor.name = "Push v2"
        await editor.save()
        #expect(editor.didSave)
        #expect(!editor.hasUnsavedChanges)
    }
}

// MARK: - Plan editor keeps unedited fields (B-6 / C-13)

@MainActor
struct PlanEditorPreservesFieldsTests {
    @Test
    func savingAnEditKeepsFieldsTheEditorDoesNotShow() async throws {
        let store = InMemoryWorkoutPlanStore(initial: [Fixtures.plan])
        let editor = PlanEditorViewModel(plan: Fixtures.plan, service: .testing(store),
                                         calendar: Fixtures.calendar, now: Fixtures.reference)
        editor.name = "Push v2"
        editor.toggle(.friday)
        await editor.save()

        let saved = try #require(store.load().first)
        #expect(store.load().count == 1)
        #expect(saved.id == Fixtures.plan.id)
        #expect(saved.name == "Push v2")
        #expect(saved.schedule == .weekly([.monday, .thursday, .friday]))
        // Untouched by the editor, so carried over as they were.
        #expect(saved.reminderTime == DateComponents(hour: 18, minute: 30))
        #expect(saved.isActive == false)
        #expect(saved.createdAt == Fixtures.plan.createdAt)
        #expect(saved.exercises == Fixtures.plan.exercises)
    }

    @Test
    func unchangedSaveRoundTripsThePlanExactly() async throws {
        let store = InMemoryWorkoutPlanStore(initial: [Fixtures.plan])
        let editor = PlanEditorViewModel(plan: Fixtures.plan, service: .testing(store),
                                         calendar: Fixtures.calendar, now: Fixtures.reference)
        await editor.save()
        #expect(try #require(store.load().first) == Fixtures.plan)
    }

    @Test
    func newPlanKeepsOneIdentityAcrossRetries() {
        let editor = PlanEditorViewModel(plan: nil, service: .testing(InMemoryWorkoutPlanStore()),
                                         calendar: Fixtures.calendar, now: Fixtures.reference)
        editor.name = "Nowy"
        editor.addExercise(Fixtures.pushUps)
        editor.toggle(.monday)

        let first = editor.editedPlan
        let second = editor.editedPlan
        #expect(first.id == second.id)
        #expect(first.createdAt == Fixtures.reference)
        #expect(first.isActive)
        #expect(first.reminderTime == nil)
    }
}
