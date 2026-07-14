//
//  HomePlannerTests.swift
//  cali-parkTests
//
//  Sprint 8 — Home surfaces the next scheduled workout: nearest-plan selection
//  from many plans, and prefilling a session's DraftItems from a plan.
//

import Foundation
import Testing
@testable import cali_park

private enum Fixtures {
    /// UTC calendar so weekday math never depends on the machine's timezone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Epoch day `n`. Day 0 (1970-01-01) is a Thursday (`.weekday` == 5).
    static func day(_ n: Int) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400)
    }
}

// MARK: - Next planned workout selection

@MainActor
struct NextPlannedWorkoutTests {
    private func dashboard(plans: [WorkoutPlan]) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(),
            planStore: InMemoryWorkoutPlanStore(initial: plans),
            calendar: Fixtures.calendar
        )
    }

    @Test
    func picksTheSoonestOccurrenceAmongPlans() {
        // Reference Thursday (day 0). Friday is one day away, Monday is four.
        let friday = WorkoutPlan(name: "Pull", schedule: .weekly([.friday]))
        let monday = WorkoutPlan(name: "Push", schedule: .weekly([.monday]))
        let vm = dashboard(plans: [monday, friday])

        let next = vm.nextPlannedWorkout(asOf: Fixtures.day(0))

        #expect(next?.plan.name == "Pull")
        #expect(next?.date == Fixtures.day(1))
    }

    @Test
    func inactivePlansAreExcluded() {
        let inactiveFriday = WorkoutPlan(name: "Skip", schedule: .weekly([.friday]), isActive: false)
        let activeMonday = WorkoutPlan(name: "Push", schedule: .weekly([.monday]))
        let vm = dashboard(plans: [inactiveFriday, activeMonday])

        let next = vm.nextPlannedWorkout(asOf: Fixtures.day(0))

        #expect(next?.plan.name == "Push")
        #expect(next?.date == Fixtures.day(4))
    }

    @Test
    func tiesBreakOnCreationOrder() {
        // Both fall on the same day; the older plan wins for a stable result.
        let older = WorkoutPlan(name: "Older", schedule: .weekly([.friday]), createdAt: Fixtures.day(0))
        let newer = WorkoutPlan(name: "Newer", schedule: .weekly([.friday]), createdAt: Fixtures.day(0) + 60)
        let vm = dashboard(plans: [newer, older])

        let next = vm.nextPlannedWorkout(asOf: Fixtures.day(0))

        #expect(next?.plan.name == "Older")
    }

    @Test
    func noScheduledPlansYieldsNil() {
        let draft = WorkoutPlan(name: "Draft", schedule: .once(nil))
        let vm = dashboard(plans: [draft])

        #expect(vm.nextPlannedWorkout(asOf: Fixtures.day(0)) == nil)
    }
}

// MARK: - Schedule "when" label

struct WorkoutScheduleDayLabelTests {
    @Test
    func todayAndTomorrowReadAsWords() {
        let reference = Fixtures.day(10)
        #expect(WorkoutScheduleFormatter.dayLabel(Fixtures.day(10), asOf: reference, calendar: Fixtures.calendar) == "Dziś")
        #expect(WorkoutScheduleFormatter.dayLabel(Fixtures.day(11), asOf: reference, calendar: Fixtures.calendar) == "Jutro")
    }

    @Test
    func daysWithinTheWeekReadAsWeekday() {
        // Reference day 0 is Thursday; +2 days is a Saturday.
        let label = WorkoutScheduleFormatter.dayLabel(Fixtures.day(2), asOf: Fixtures.day(0), calendar: Fixtures.calendar)
        #expect(!label.isEmpty)
        #expect(label != "Dziś")
        #expect(label != "Jutro")
    }
}

// MARK: - Prefilling a session from a plan

@MainActor
struct QuickWorkoutPrefillTests {
    @Test
    func draftItemExpandsTargetsIntoConcreteSets() {
        let planned = PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID, targetSets: 3, targetReps: 8)

        let item = QuickWorkoutViewModel.draftItem(from: planned)

        #expect(item?.exercise.id == ExerciseCatalog.pullUpsID)
        #expect(item?.sets.map(\.reps) == [8, 8, 8])
        #expect(item?.isPending == false)
    }

    @Test
    func draftItemWithoutTargetsStaysPending() {
        let planned = PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)

        let item = QuickWorkoutViewModel.draftItem(from: planned)

        #expect(item?.sets.isEmpty == true)
        #expect(item?.isPending == true)
    }

    @Test(arguments: [
        (nil, nil),
        (3, nil),
        (nil, 8),
        (0, 8),
        (3, 0)
    ] as [(Int?, Int?)])
    func incompleteOrZeroTargetsProduceNoSets(targetSets: Int?, targetReps: Int?) {
        let planned = PlannedExercise(
            exerciseID: ExerciseCatalog.dipsID,
            targetSets: targetSets,
            targetReps: targetReps
        )

        #expect(QuickWorkoutViewModel.prefilledSets(from: planned).isEmpty)
    }

    @Test
    func unknownExerciseIsDropped() {
        let planned = PlannedExercise(exerciseID: UUID())

        #expect(QuickWorkoutViewModel.draftItem(from: planned) == nil)
    }

    @Test
    func sessionSeededFromPlanQueuesEveryExercise() {
        let plan = WorkoutPlan(
            name: "Pull",
            exercises: [
                PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID, targetSets: 3, targetReps: 8),
                PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)
            ],
            schedule: .weekly([.monday])
        )
        let vm = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore(), plan: plan)

        #expect(vm.exerciseCount == 2)
        #expect(vm.totalSets == 3)          // only the prefilled exercise has sets
        #expect(vm.canFinish)               // one non-pending item is enough
    }

    @Test
    func pendingSessionCannotFinishUntilASetIsLogged() throws {
        let plan = WorkoutPlan(
            name: "Push",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID)],
            schedule: .weekly([.monday])
        )
        let store = InMemoryWorkoutLogStore()
        let vm = QuickWorkoutViewModel(store: store, plan: plan)

        #expect(!vm.canFinish)
        vm.finish()
        #expect(store.load().isEmpty) // nothing logged yet — no-op

        let pending = try #require(vm.items.first)
        vm.updateSets(itemID: pending.id, sets: [LoggedSet(reps: 10), LoggedSet(reps: 10)])

        #expect(vm.canFinish)
        vm.finish()

        let saved = store.load()
        #expect(saved.count == 1)
        #expect(saved.first?.sets.map(\.reps) == [10, 10])
        #expect(vm.didFinish)
    }

    @Test
    func finishSavesOnlyConfirmedItemsUnderOneSession() throws {
        let plan = WorkoutPlan(
            name: "Mixed",
            exercises: [
                PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID, targetSets: 2, targetReps: 5),
                PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID) // stays pending
            ],
            schedule: .weekly([.monday])
        )
        let store = InMemoryWorkoutLogStore()
        let vm = QuickWorkoutViewModel(store: store, plan: plan)

        vm.finish()

        let saved = store.load()
        #expect(saved.count == 1) // pending push-ups skipped
        #expect(saved.first?.exerciseID == ExerciseCatalog.pullUpsID)
        #expect(Set(saved.compactMap(\.sessionID)).count == 1)
    }
}
