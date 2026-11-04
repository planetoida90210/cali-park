//
//  ProgramGraduationTests.swift
//  cali-parkTests
//
//  "Czas na Fundamenty": a finished "Pierwsze podciągnięcie" plan suggests
//  moving on, one tap replaces it, and a dismissed card stays gone.
//

import Foundation
import Testing
@testable import cali_park

private typealias E = ExerciseCatalog

// MARK: - Candidate

@Suite("Which plan is ready to move on to Fundamenty")
struct GraduationCandidateTests {
    private static let ready = ProgramFixtures.states(logs: [ProgramFixtures.reps(E.pullUpsID, 8)])
    private static let notYet = ProgramFixtures.states(logs: [ProgramFixtures.reps(E.pullUpsID, 7)])

    private static func plan(_ program: ProgramID, isActive: Bool = true, createdAt: Date = ProgramFixtures.today) -> WorkoutPlan {
        WorkoutPlan(name: program.rawValue, schedule: .weekly([.monday]), isActive: isActive,
                    createdAt: createdAt, programID: program.rawValue, programVersion: 1)
    }

    @Test
    func aFinishedFirstPullUpPlanIsTheCandidate() {
        let plan = Self.plan(.firstPullUp)
        #expect(ProgramPrescriber.graduationCandidate(plans: [plan], pathStates: Self.ready) == plan)
        #expect(ProgramPrescriber.graduationCandidate(plans: [plan], pathStates: Self.notYet) == nil)
    }

    @Test
    func anExistingFundamentalsPlanMeansNoSuggestion() {
        let plans = [Self.plan(.firstPullUp), Self.plan(.fundamentals)]
        #expect(ProgramPrescriber.graduationCandidate(plans: plans, pathStates: Self.ready) == nil)
    }

    @Test
    func inactiveAndOtherPlansAreNotCandidates() {
        let plans = [Self.plan(.firstPullUp, isActive: false), Self.plan(.minimum),
                     WorkoutPlan(name: "Mój", schedule: .weekly([.friday]))]
        #expect(ProgramPrescriber.graduationCandidate(plans: plans, pathStates: Self.ready) == nil)
    }

    @Test
    func theOldestFirstPullUpPlanIsChosen() {
        let older = Self.plan(.firstPullUp, createdAt: ProgramFixtures.today.addingTimeInterval(-86_400))
        let newer = Self.plan(.firstPullUp)
        #expect(ProgramPrescriber.graduationCandidate(plans: [newer, older], pathStates: Self.ready) == older)
    }

    @Test
    func replacementKeepsTheDaysAndTheReminder() throws {
        var old = Self.plan(.firstPullUp)
        old.schedule = .weekly([.tuesday, .thursday, .saturday])
        old.reminderTime = DateComponents(hour: 18, minute: 30)

        let replacement = try #require(ProgramPrescriber.replacementPlans(
            for: old, program: ProgramCatalog.fundamentals, pathStates: Self.ready, today: ProgramFixtures.today
        ).first)
        #expect(replacement.programID == ProgramID.fundamentals.rawValue)
        #expect(replacement.schedule == old.schedule)
        #expect(replacement.reminderTime == old.reminderTime)
        #expect(replacement.createdAt == ProgramFixtures.today)
        // Full pull-ups are conquered, so the pair starts on the rung above.
        let current = try #require(ProgramPrescriber.currentStep(on: .pullUp, pathStates: Self.ready))
        #expect(current.exerciseID != E.pullUpsID)
        #expect(replacement.exercises.first?.exerciseID == current.exerciseID)
    }
}

// MARK: - Card

@MainActor
@Suite("The Planner's Czas na Fundamenty card", .timeLimit(.minutes(1)))
struct ProgramGraduationViewModelTests {
    private struct Harness {
        let plans: InMemoryWorkoutPlanStore
        let defaults: UserDefaults
        let viewModel: ProgramGraduationViewModel
        let firstPullUp: WorkoutPlan
    }

    private static func harness(planStore: WorkoutPlanStoring? = nil,
                                logs: [WorkoutLogEntry] = [ProgramFixtures.reps(E.pullUpsID, 8)]) throws -> Harness {
        var firstPullUp = try #require(ProgramPrescriber.plans(for: ProgramCatalog.firstPullUp,
                                                              pathStates: ProgramFixtures.newcomer,
                                                              today: ProgramFixtures.today).first)
        firstPullUp.reminderTime = DateComponents(hour: 7, minute: 0)
        let store = InMemoryWorkoutPlanStore(initial: [firstPullUp])
        let defaults = UserDefaults.throwaway()
        let starter = ProgramStarter(planService: .testing(planStore ?? store),
                                     logStore: InMemoryWorkoutLogStore(initial: logs),
                                     placementStore: InMemorySkillPlacementStore(),
                                     calendar: ProgramFixtures.calendar,
                                     clock: { ProgramFixtures.today })
        return Harness(plans: store, defaults: defaults,
                       viewModel: ProgramGraduationViewModel(starter: starter, defaults: defaults),
                       firstPullUp: firstPullUp)
    }

    @Test
    func showsOnlyWhenFullPullUpsAreConquered() throws {
        let ready = try Self.harness()
        ready.viewModel.reload()
        #expect(ready.viewModel.candidate == ready.firstPullUp)

        let notYet = try Self.harness(logs: [ProgramFixtures.reps(E.pullUpsID, 7)])
        notYet.viewModel.reload()
        #expect(notYet.viewModel.candidate == nil)
    }

    @Test
    func moveOnReplacesThePlanOnTheSameDays() async throws {
        let harness = try Self.harness()
        harness.viewModel.reload()

        let created = try #require(await harness.viewModel.moveOn())

        let saved = harness.plans.load()
        #expect(saved == [created])
        #expect(created.programID == ProgramID.fundamentals.rawValue)
        #expect(created.schedule == harness.firstPullUp.schedule)
        #expect(created.reminderTime == DateComponents(hour: 7, minute: 0))
        #expect(harness.viewModel.candidate == nil)
        #expect(harness.defaults.bool(forKey: DefaultsKey.hasDismissedFundamentalsHint.rawValue))
    }

    @Test
    func aDismissedCardDoesNotComeBack() throws {
        let harness = try Self.harness()
        harness.viewModel.reload()
        harness.viewModel.dismiss()
        harness.viewModel.reload()

        #expect(harness.viewModel.candidate == nil)
        #expect(harness.plans.load() == [harness.firstPullUp])
    }

    @Test
    func aRefusedSaveKeepsTheOldPlanAndTheCard() async throws {
        let harness = try Self.harness()
        let store = PlanStoreRefusing(initial: [harness.firstPullUp], refuseSave: true)
        let viewModel = try Self.viewModel(over: store)
        viewModel.reload()

        #expect(await viewModel.moveOn() == nil)
        #expect(viewModel.errorMessage == "Nie udało się utworzyć planu.")
        #expect(store.plans == [harness.firstPullUp])
        #expect(viewModel.candidate == harness.firstPullUp)
    }

    @Test
    func aRefusedDeleteKeepsBothPlansAndSaysSo() async throws {
        let harness = try Self.harness()
        let store = PlanStoreRefusing(initial: [harness.firstPullUp], refuseDelete: true)
        let viewModel = try Self.viewModel(over: store)
        viewModel.reload()

        #expect(await viewModel.moveOn() == nil)
        #expect(store.plans.count == 2)
        #expect(viewModel.errorMessage?.contains("nie udało się usunąć planu") == true)
        #expect(viewModel.candidate == nil)
    }

    private static func viewModel(over store: WorkoutPlanStoring) throws -> ProgramGraduationViewModel {
        let starter = ProgramStarter(planService: .testing(store),
                                     logStore: InMemoryWorkoutLogStore(initial: [ProgramFixtures.reps(E.pullUpsID, 8)]),
                                     placementStore: InMemorySkillPlacementStore(),
                                     calendar: ProgramFixtures.calendar,
                                     clock: { ProgramFixtures.today })
        return ProgramGraduationViewModel(starter: starter, defaults: .throwaway())
    }
}

// MARK: - PlanStoreRefusing
/// Lists its plans, and refuses saves or deletes on request.
private final class PlanStoreRefusing: WorkoutPlanStoring {
    struct WriteError: Error {}
    private(set) var plans: [WorkoutPlan]
    private let refuseSave: Bool
    private let refuseDelete: Bool

    init(initial: [WorkoutPlan], refuseSave: Bool = false, refuseDelete: Bool = false) {
        plans = initial
        self.refuseSave = refuseSave
        self.refuseDelete = refuseDelete
    }

    func load() throws -> [WorkoutPlan] { plans }

    func save(_ plan: WorkoutPlan) throws {
        if refuseSave { throw WriteError() }
        plans.removeAll { $0.id == plan.id }
        plans.append(plan)
    }

    func delete(id: UUID) throws {
        if refuseDelete { throw WriteError() }
        plans.removeAll { $0.id == id }
    }
}
