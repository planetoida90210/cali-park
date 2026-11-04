//
//  HomeHeroStateTests.swift
//  cali-parkTests
//
//  Contextual Home hero foundation: the pure state resolver
//  (HomeDashboardViewModel.heroState(asOf:)), backward-compatible planID
//  persistence on WorkoutLogEntry, and finish() stamping the plan.
//

import Foundation
import Testing

@testable import cali_park

private enum Fixtures {
    /// UTC calendar so weekday/day math never depends on the machine's timezone.
    static let calendar = TestCalendar.utc

    /// Epoch day `n`. Day 0 (1970-01-01) is a Thursday (`.weekday` == 5).
    static func day(_ n: Int) -> Date {
        TestDate.epochDay(n)
    }

    /// A moment partway through day `n`, to prove same-day matching ignores the
    /// time of day.
    static func middayOf(_ n: Int) -> Date {
        day(n) + 12 * 3_600
    }
}

// MARK: - heroState resolution

@MainActor
struct HomeHeroStateResolutionTests {
    private func dashboard(
        plans: [WorkoutPlan] = [],
        entries: [WorkoutLogEntry] = []
    ) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: entries),
            planService: .testing(InMemoryWorkoutPlanStore(initial: plans)),
            placementStore: InMemorySkillPlacementStore(),
            goalStore: InMemoryWeeklyGoalStore(),
            calendar: Fixtures.calendar,
            clock: { Fixtures.middayOf(0) }
        )
    }

    /// A one-off plan whose day has passed is not offered on Home: no
    /// "Rozpocznij", no "Następny trening".
    @Test
    func expiredOneOffPlanIsNotOffered() {
        let expired = WorkoutPlan(
            name: "Wczoraj",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)],
            schedule: .once(Fixtures.day(9), in: Fixtures.calendar))
        let viewModel = dashboard(plans: [expired])

        #expect(viewModel.heroState(asOf: Fixtures.middayOf(10)) == .firstRun)
    }

    /// A plan scheduled on the reference day (Thursday, day 0).
    private func thursdayPlan(name: String = "Pull") -> WorkoutPlan {
        WorkoutPlan(
            name: name,
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)],
            schedule: .weekly([.thursday]))
    }

    // Parameterized happy path: each scenario must land on exactly one case.
    enum Scenario: String, CaseIterable, Sendable {
        case planTodayNotDone
        case planTodayDone
        case trainedTodayNoPlan
        case planTomorrow
        case historyNoPlans
        case emptyJournal
    }

    @Test(arguments: Scenario.allCases)
    func resolvesTheExpectedCase(_ scenario: Scenario) {
        let reference = Fixtures.middayOf(0) // Thursday
        let plan = thursdayPlan()

        let vm: HomeDashboardViewModel
        switch scenario {
        case .planTodayNotDone:
            vm = dashboard(plans: [plan])
        case .planTodayDone:
            let done = WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                date: Fixtures.middayOf(0),
                sets: [LoggedSet(reps: 8)],
                planID: plan.id)
            vm = dashboard(plans: [plan], entries: [done])
        case .trainedTodayNoPlan:
            let free = WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pushUpsID,
                date: Fixtures.middayOf(0),
                sets: [LoggedSet(reps: 20)])
            vm = dashboard(entries: [free])
        case .planTomorrow:
            let friday = WorkoutPlan(name: "Push", schedule: .weekly([.friday]))
            vm = dashboard(plans: [friday])
        case .historyNoPlans:
            let past = WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                date: Fixtures.day(-3),
                sets: [LoggedSet(reps: 6)])
            vm = dashboard(entries: [past])
        case .emptyJournal:
            vm = dashboard()
        }

        let state = vm.heroState(asOf: reference)

        switch scenario {
        case .planTodayNotDone:
            #expect(state.isPlanToday)
        case .planTodayDone, .trainedTodayNoPlan:
            #expect(state.isCompletedToday)
        case .planTomorrow:
            #expect(state.isRestDay)
        case .historyNoPlans:
            #expect(state.isFreeMode)
        case .emptyJournal:
            #expect(state == .firstRun)
        }
    }

    @Test
    func planTodayCarriesThePlanAndTodaysProgress() throws {
        let plan = thursdayPlan(name: "Pull")
        // A free log earlier today (no matching planID) is progress, not "done".
        let free = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pushUpsID,
            date: Fixtures.day(0) + 3_600,
            sets: [LoggedSet(reps: 12), LoggedSet(reps: 8)])
        let vm = dashboard(plans: [plan], entries: [free])

        guard case .planToday(let resolvedPlan, let loggedTodayReps, _) = vm.heroState(asOf: Fixtures.middayOf(0)) else {
            Issue.record("expected .planToday")
            return
        }
        #expect(resolvedPlan == plan)
        #expect(loggedTodayReps == 20)
    }

    /// B-12: a hold-only start shows as progress too, in seconds.
    @Test
    func planTodayCountsHoldsLoggedToday() throws {
        let plan = thursdayPlan(name: "Pull")
        let hold = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pushUpsID,
            date: Fixtures.day(0) + 3_600,
            sets: [LoggedSet(value: 20, measurement: .seconds), LoggedSet(value: 15, measurement: .seconds)])
        let vm = dashboard(plans: [plan], entries: [hold])

        #expect(
            vm.heroState(asOf: Fixtures.middayOf(0))
                == .planToday(plan: plan, loggedTodayReps: 0, loggedTodaySeconds: 35))
    }

    @Test
    func planIsDoneOnlyWhenTodaysLogCarriesItsPlanID() {
        let plan = thursdayPlan()
        // Logged today, but from a *different* plan — today's plan isn't done.
        let otherPlanLog = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: Fixtures.middayOf(0),
            sets: [LoggedSet(reps: 8)],
            planID: UUID())
        let vm = dashboard(plans: [plan], entries: [otherPlanLog])

        #expect(vm.heroState(asOf: Fixtures.middayOf(0)).isPlanToday)
    }

    @Test
    func restDayReportsTheNextPlanAndDay() throws {
        let friday = WorkoutPlan(name: "Push", schedule: .weekly([.friday]))
        let vm = dashboard(plans: [friday])

        guard case .restDay(let nextPlan, let date, _) = vm.heroState(asOf: Fixtures.middayOf(0)) else {
            Issue.record("expected .restDay")
            return
        }
        #expect(nextPlan == friday)
        #expect(date == Fixtures.day(1)) // Friday, start of day
    }

    @Test
    func freeModeSurfacesLastWorkoutAndStreak() throws {
        // Two consecutive past days keep a streak of 0 today (gap since day -1).
        let past = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: Fixtures.day(-3),
            sets: [LoggedSet(reps: 6)])
        let vm = dashboard(entries: [past])

        guard case .freeMode(let lastWorkout, _, let streak) = vm.heroState(asOf: Fixtures.middayOf(0)) else {
            Issue.record("expected .freeMode")
            return
        }
        #expect(lastWorkout.entries == [past])
        #expect(streak.current == 0)
    }

    @Test
    func completedTodayCountsTodayIntoTheStreak() throws {
        let plan = thursdayPlan()
        let done = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: Fixtures.middayOf(0),
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 8)],
            planID: plan.id)
        let vm = dashboard(plans: [plan], entries: [done])

        guard case .completedToday(let summary, let streak) = vm.heroState(asOf: Fixtures.middayOf(0)) else {
            Issue.record("expected .completedToday")
            return
        }
        #expect(summary.totalReps == 16)
        #expect(streak.current == 1)
    }
}

// MARK: - WorkoutLogEntry planID Codable (backward compatibility)

struct WorkoutLogEntryPlanIDCodableTests {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    @Test
    func planIDRoundtrips() throws {
        let planID = UUID()
        // ISO 8601 stores whole seconds, so a sub-second `.now` wouldn't roundtrip.
        let entry = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: Date(timeIntervalSince1970: 1_000_000),
            sets: [LoggedSet(reps: 6)],
            sessionID: UUID(),
            planID: planID)

        let data = try Self.encoder.encode(entry)
        let decoded = try Self.decoder.decode(WorkoutLogEntry.self, from: data)

        #expect(decoded.planID == planID)
        #expect(decoded == entry)
    }

    /// Entries saved before plans stamped their sessions have no `planID` key
    /// and must still decode (to `nil`).
    @Test
    func legacyJSONWithoutPlanIDDecodesToNil() throws {
        let json = """
            {
                "id": "22222222-2222-4222-8222-222222222222",
                "exerciseID": "E0000000-0000-4000-8000-000000000001",
                "date": "2026-01-01T10:00:00Z",
                "sets": [{ "reps": 6 }],
                "sessionID": "33333333-3333-4333-8333-333333333333"
            }
            """
        let data = Data(json.utf8)

        let decoded = try Self.decoder.decode(WorkoutLogEntry.self, from: data)

        #expect(decoded.planID == nil)
        #expect(decoded.sessionID != nil)
    }
}

// MARK: - finish() stamps the plan

@MainActor
struct QuickWorkoutPlanIDTests {
    @Test
    func finishStampsEveryEntryWithThePlanID() async throws {
        let plan = WorkoutPlan(
            name: "Pull",
            exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID, targetSets: 2, targetReps: 5)],
            schedule: .weekly([.monday])
        )
        let store = InMemoryWorkoutLogStore()
        let vm = QuickWorkoutViewModel(store: store, plan: plan)

        await vm.finish()

        let saved = store.load()
        #expect(saved.map(\.exerciseID) == [ExerciseCatalog.pullUpsID])
        #expect(saved.map(\.planID) == [plan.id])
    }

    @Test
    func freeSessionSavesWithoutAPlanID() async throws {
        let store = InMemoryWorkoutLogStore()
        let vm = QuickWorkoutViewModel(store: store)
        vm.addExercise(ExerciseCatalog.all[0], sets: [LoggedSet(reps: 6)])

        await vm.finish()

        let saved = store.load()
        #expect(saved.count == 1)
        #expect(saved.first?.planID == nil)
    }
}
