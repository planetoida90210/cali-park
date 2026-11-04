import Foundation
import Testing

@testable import cali_park

private typealias E = ExerciseCatalog

@MainActor
private func makeStarter(
    plans: WorkoutPlanStoring = InMemoryWorkoutPlanStore(),
    logs: WorkoutLogStoring = InMemoryWorkoutLogStore(),
    placement: SkillPlacement? = nil
) -> ProgramStarter {
    ProgramStarter(
        planService: .testing(plans),
        logStore: logs,
        placementStore: InMemorySkillPlacementStore(initial: placement),
        calendar: ProgramFixtures.calendar,
        clock: { ProgramFixtures.today })
}

// MARK: - Starter

@MainActor
@Suite("ProgramStarter saves prescribed plans through WorkoutPlanService", .timeLimit(.minutes(1)))
struct ProgramStarterTests {
    @Test
    func startSavesThePlansOnTheDeclaredRungs() async throws {
        let store = InMemoryWorkoutPlanStore()
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 3], declaredAt: ProgramFixtures.today)
        let starter = makeStarter(plans: store, placement: placement)

        let created = try await starter.start(ProgramCatalog.firstPullUp)

        #expect(store.load() == created)
        let plan = try #require(created.first)
        #expect(plan.programID == "firstPullUp")
        #expect(plan.createdAt == ProgramFixtures.today)
        #expect(plan.exercises.first?.exerciseID == E.negativePullUpsID)
    }

    @Test
    func unreadableJournalCreatesNothing() async {
        let store = InMemoryWorkoutPlanStore()
        let starter = makeStarter(plans: store, logs: UnreadableWorkoutLogStore())

        await #expect(throws: ProgramStartError.ladderStateUnreadable) {
            try await starter.start(ProgramCatalog.fundamentals)
        }
        #expect(store.load().isEmpty)
    }

    @Test
    func refusedSaveIsReported() async {
        let starter = makeStarter(plans: ReadOnlyPlanStore())

        await #expect(throws: ProgramStartError.saveFailed) {
            try await starter.start(ProgramCatalog.minimum)
        }
    }
}

// MARK: - Planner: program detail

@MainActor
@Suite("Program detail screen", .timeLimit(.minutes(1)))
struct ProgramDetailViewModelTests {
    @Test
    func previewShowsThePlanOnTheCurrentRungs() {
        let viewModel = ProgramDetailViewModel(program: ProgramCatalog.fundamentals, starter: makeStarter())
        viewModel.reload()

        #expect(viewModel.previewPlans.count == 1)
        #expect(viewModel.previewPlans.first?.exercises.first?.exerciseID == E.deadHangID)
        #expect(viewModel.showsFirstPullUpHint)
        #expect(viewModel.canCreate)
        #expect(viewModel.scheduleSummary == "Co tydzień · Pon, Śr, Pt")
    }

    @Test
    func noHintOnceFullPullUpsAreReached() {
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: E.pullUpsID], declaredAt: ProgramFixtures.today)
        let viewModel = ProgramDetailViewModel(
            program: ProgramCatalog.fundamentals,
            starter: makeStarter(placement: placement))
        viewModel.reload()
        #expect(viewModel.showsFirstPullUpHint == false)
    }

    @Test
    func hintOnlyOnFundamentals() {
        let viewModel = ProgramDetailViewModel(program: ProgramCatalog.minimum, starter: makeStarter())
        viewModel.reload()
        #expect(viewModel.showsFirstPullUpHint == false)
    }

    @Test
    func createSavesOneEditablePlanAndOnlyOnce() async throws {
        let store = InMemoryWorkoutPlanStore()
        let viewModel = ProgramDetailViewModel(program: ProgramCatalog.skills, starter: makeStarter(plans: store))

        await viewModel.create()
        await viewModel.create()

        let created = try #require(viewModel.createdPlans)
        #expect(store.load() == created)
        #expect(store.load().count == 1)
        #expect(created.first?.programID == "skills")
        #expect(created.first?.programVersion == 1)
        #expect(viewModel.canCreate == false)
        #expect(viewModel.errorMessage == nil)

        // The created plan opens in the normal editor, which keeps the origin.
        let editor = PlanEditorViewModel(
            plan: created.first, service: .testing(store),
            calendar: ProgramFixtures.calendar, now: ProgramFixtures.today)
        #expect(editor.programOrigin?.line == "Program Skille · wersja 1")
        #expect(editor.editedPlan.programID == "skills")
        #expect(editor.editedPlan.exercises == created.first?.exercises)
    }

    @Test
    func unreadableJournalShowsAnErrorAndBlocksCreating() async {
        let store = InMemoryWorkoutPlanStore()
        let viewModel = ProgramDetailViewModel(
            program: ProgramCatalog.fundamentals,
            starter: makeStarter(plans: store, logs: UnreadableWorkoutLogStore()))
        #expect(viewModel.hasLoadError == false, "The init reads nothing")
        #expect(viewModel.errorMessage == nil)
        viewModel.reload()

        #expect(viewModel.hasLoadError)
        #expect(viewModel.errorMessage == StoreLoadFailure.message)
        #expect(viewModel.canCreate == false)

        await viewModel.create()
        #expect(store.load().isEmpty)
    }

    @Test
    func failedSaveShowsAnError() async {
        let viewModel = ProgramDetailViewModel(
            program: ProgramCatalog.minimum,
            starter: makeStarter(plans: ReadOnlyPlanStore()))

        await viewModel.create()

        #expect(viewModel.createdPlans == nil)
        #expect(viewModel.errorMessage == "Nie udało się utworzyć planu.")
        #expect(viewModel.canCreate)
    }

    @Test
    func targetSummariesReadLikeTheProgram() throws {
        let viewModel = ProgramDetailViewModel(program: ProgramCatalog.fundamentals, starter: makeStarter())
        viewModel.reload()
        let plan = try #require(viewModel.previewPlans.first)

        #expect(viewModel.targetSummary(for: plan.exercises[0], in: plan) == "Para 1 · 3 × 10–30 s · przerwa 90 s".keptTogether)
        #expect(viewModel.targetSummary(for: plan.exercises[1], in: plan) == "Para 1 · 3 × 5–8 · przerwa 90 s".keptTogether)
    }
}

// MARK: - Formatting

@Suite("Program item labels")
struct ProgramFormatTests {
    @Test
    func circuitTimeBoxAndTotalHold() throws {
        let taps = PlannedExercise(exerciseID: E.plankShoulderTapsID, group: 1, rounds: 2...6, repsInReserve: 2)
        let practice = PlannedExercise(exerciseID: E.wallPlankID, timeBoxMinutes: 10)
        let lSit = PlannedExercise(exerciseID: E.oneLegLSitID, targetSeconds: 30, targetSecondsMin: 10, totalSeconds: 180)

        #expect(
            ProgramFormat.doseSummary(for: taps, exercise: E.exercise(withID: E.plankShoulderTapsID))
                == "2–6 rund · 1–2 powtórzenia w zapasie na stronę".keptTogether)
        #expect(ProgramFormat.groupLabel(for: taps, in: [taps]) == "Obwód")
        #expect(ProgramFormat.doseSummary(for: practice, exercise: nil) == "do 10 min praktyki".keptTogether)
        #expect(
            ProgramFormat.doseSummary(for: lSit, exercise: E.exercise(withID: E.oneLegLSitID))
                == "łącznie do 3 min, holdy 10–30 s na stronę".keptTogether)
    }

    @Test
    func unilateralSetsAndHandBuiltItems() {
        let lunges = PlannedExercise(exerciseID: E.lungesID, targetSets: 3, targetReps: 8, targetRepsMin: 5)
        let handBuilt = PlannedExercise(exerciseID: E.pushUpsID)
        let fixed = PlannedExercise(exerciseID: E.pushUpsID, targetSets: 3, targetReps: 12)

        #expect(ProgramFormat.doseSummary(for: lunges, exercise: E.exercise(withID: E.lungesID)) == "3 × 5–8 na nogę".keptTogether)
        #expect(ProgramFormat.doseSummary(for: handBuilt, exercise: nil) == nil)
        #expect(ProgramFormat.doseSummary(for: fixed, exercise: nil) == "3 × 12".keptTogether)
        #expect(ProgramFormat.groupLabel(for: fixed, in: [fixed]) == nil)
        #expect(ProgramFormat.restSummary(for: fixed) == nil)
    }
}

// MARK: - Onboarding: program choice

@MainActor
@Suite("Onboarding suggests a program after the level test", .timeLimit(.minutes(1)))
struct ProgramChoiceViewModelTests {
    private static let zeroPullUps = PlacementCalibration.placement(
        repAnswers: [.pullUp: .none], masteredSkills: [], ownsBand: false, declaredAt: ProgramFixtures.today)
    private static let somePullUps = PlacementCalibration.placement(
        repAnswers: [.pullUp: .few], masteredSkills: [], ownsBand: false, declaredAt: ProgramFixtures.today)

    @Test
    func choiceFollowsTheSuggestionUntilThePlayerPicks() {
        let viewModel = ProgramChoiceViewModel(starter: makeStarter())

        viewModel.updateSuggestion(for: Self.zeroPullUps)
        #expect(viewModel.suggested == .firstPullUp)
        #expect(viewModel.choice == .program(.firstPullUp))

        viewModel.updateSuggestion(for: Self.somePullUps)
        #expect(viewModel.choice == .program(.fundamentals))

        viewModel.pick(.program(.minimum))
        viewModel.updateSuggestion(for: Self.zeroPullUps)
        #expect(viewModel.suggested == .firstPullUp)
        #expect(viewModel.choice == .program(.minimum))
    }

    @Test
    func creatingTheChoiceSavesItsPlan() async {
        let store = InMemoryWorkoutPlanStore()
        let viewModel = ProgramChoiceViewModel(starter: makeStarter(plans: store, placement: Self.zeroPullUps))
        viewModel.updateSuggestion(for: Self.zeroPullUps)

        #expect(await viewModel.createChosenProgram())

        #expect(store.load().map(\.programID) == ["firstPullUp"])
        #expect(store.load().first?.exercises.first?.exerciseID == E.negativePullUpsID)
    }

    @Test
    func noProgramCreatesNothing() async {
        let store = InMemoryWorkoutPlanStore()
        let viewModel = ProgramChoiceViewModel(starter: makeStarter(plans: store))
        viewModel.pick(.none)

        #expect(await viewModel.createChosenProgram())
        #expect(store.load().isEmpty)
    }

    @Test
    func failureIsReported() async {
        let viewModel = ProgramChoiceViewModel(starter: makeStarter(plans: ReadOnlyPlanStore()))
        viewModel.pick(.program(.skills))

        #expect(await viewModel.createChosenProgram() == false)
        #expect(viewModel.errorMessage?.contains("Skille") == true)
    }
}

// MARK: - Sessions from a program plan

@MainActor
@Suite("A session from a program plan trains the current rung")
struct ProgramSessionTests {
    private static func firstPullUpPlan() throws -> WorkoutPlan {
        try #require(
            ProgramPrescriber.plans(
                for: ProgramCatalog.firstPullUp,
                pathStates: ProgramFixtures.newcomer,
                today: ProgramFixtures.today
            ).first)
    }

    @Test
    func holdsPrefillAsSeconds() throws {
        let session = QuickWorkoutViewModel(
            store: InMemoryWorkoutLogStore(), plan: try Self.firstPullUpPlan(),
            pathStates: ProgramFixtures.newcomer, logs: [])

        let deadHang = try #require(session.items.first)
        #expect(deadHang.exercise.id == E.deadHangID)
        #expect(deadHang.sets == Array(repeating: LoggedSet(reps: 1, durationSeconds: 10), count: 3))
    }

    @Test
    func aConqueredRungMovesTheSessionUpAndAddsARep() throws {
        let logs = [
            ProgramFixtures.hold(E.deadHangID, 30),
            ProgramFixtures.reps(E.inclineRowsID, 6)
        ]
        let session = QuickWorkoutViewModel(
            store: InMemoryWorkoutLogStore(), plan: try Self.firstPullUpPlan(),
            pathStates: ProgramFixtures.states(logs: logs), logs: logs)

        #expect(session.items.map(\.exercise.id) == [E.scapularPullsID, E.inclineRowsID, E.wallPushUpsID, E.assistedSquatsID])
        #expect(session.items[0].sets.map(\.reps) == [5, 5, 5]) // new rung: bottom of 3 × 5–8
        #expect(session.items[1].sets.map(\.reps) == [7, 7, 7]) // last session 6 → +1
    }

    @Test
    func withoutLadderStateItemsKeepTheirStoredExercise() throws {
        let session = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore(), plan: try Self.firstPullUpPlan())
        #expect(session.items.first?.exercise.id == E.deadHangID)
    }

    @Test
    func aLegacyHoldTargetPrefillsSecondsNotReps() {
        // Audit A-8: a hold planned with `targetReps` used to save rep sets.
        let planned = PlannedExercise(exerciseID: E.plankID, targetSets: 2, targetReps: 45)

        let item = QuickWorkoutViewModel.draftItem(from: planned)

        #expect(item?.sets == [LoggedSet(reps: 1, durationSeconds: 45), LoggedSet(reps: 1, durationSeconds: 45)])
    }

    @Test
    func homeStartsProgramPlansOnTheCurrentRung() throws {
        let plan = try Self.firstPullUpPlan()
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: E.archHangID], declaredAt: ProgramFixtures.today)
        let home = HomeHarness(
            logStore: InMemoryWorkoutLogStore(),
            planStore: InMemoryWorkoutPlanStore(initial: [plan]),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            calendar: ProgramFixtures.calendar,
            clock: { ProgramFixtures.today })

        let session = home.makeQuickWorkoutViewModel(plan: plan)

        #expect(session.items.first?.exercise.id == E.archHangID)
    }

    @Test
    func homeKeepsStoredExercisesWhenTheJournalIsUnreadable() throws {
        let plan = try Self.firstPullUpPlan()
        let placement = SkillPlacement(declaredStepByPath: [.pullUp: E.archHangID], declaredAt: ProgramFixtures.today)
        let home = HomeHarness(
            logStore: UnreadableWorkoutLogStore(),
            planStore: InMemoryWorkoutPlanStore(initial: [plan]),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            calendar: ProgramFixtures.calendar,
            clock: { ProgramFixtures.today })

        let session = home.makeQuickWorkoutViewModel(plan: plan)

        #expect(session.items.first?.exercise.id == E.deadHangID)
    }
}

// MARK: - "Utwórz plan": cancel and duplicates

@MainActor
@Suite("Utwórz plan: Anuluj deletes the new plan, a second copy asks first", .timeLimit(.minutes(1)))
struct ProgramCreateCancelTests {
    private func editor(for plan: WorkoutPlan?, service: WorkoutPlanService, isJustCreated: Bool) -> PlanEditorViewModel {
        PlanEditorViewModel(
            plan: plan, service: service, isJustCreated: isJustCreated,
            calendar: ProgramFixtures.calendar, now: ProgramFixtures.today)
    }

    @Test
    func cancelRightAfterCreationDeletesThePlanAndResyncsReminders() async throws {
        let store = InMemoryWorkoutPlanStore()
        let scheduler = InMemoryReminderScheduler(status: .authorized)
        let service = WorkoutPlanService.testing(store, scheduler: scheduler)
        let created = try #require(try await makeStarter(plans: store).start(ProgramCatalog.minimum).first)
        let syncsBefore = await scheduler.rescheduleCount

        let viewModel = editor(for: created, service: service, isJustCreated: true)
        let mayClose = await viewModel.cancel()

        #expect(mayClose)
        #expect(store.load().isEmpty)
        #expect(await scheduler.rescheduleCount == syncsBefore + 1)
    }

    @Test
    func cancelOnAnExistingPlanKeepsIt() async throws {
        let store = InMemoryWorkoutPlanStore()
        let created = try #require(try await makeStarter(plans: store).start(ProgramCatalog.minimum).first)

        let viewModel = editor(for: created, service: .testing(store), isJustCreated: false)
        #expect(await viewModel.cancel())
        #expect(store.load() == [created])
    }

    @Test
    func cancelAfterSavingKeepsThePlan() async throws {
        let store = InMemoryWorkoutPlanStore()
        let created = try #require(try await makeStarter(plans: store).start(ProgramCatalog.minimum).first)

        let viewModel = editor(for: created, service: .testing(store), isJustCreated: true)
        await viewModel.save()
        #expect(viewModel.didSave)
        #expect(await viewModel.cancel())
        #expect(store.load().count == 1)
    }

    @Test
    func failedDeleteShowsAnErrorAndKeepsTheEditorOpen() async {
        let plan = WorkoutPlan(name: "Minimum", schedule: .weekly([.monday]), programID: "minimum", programVersion: 1)
        let viewModel = editor(for: plan, service: .testing(ReadOnlyPlanStore()), isJustCreated: true)

        #expect(await viewModel.cancel() == false)
        #expect(viewModel.errorMessage == "Nie udało się usunąć planu.")
    }

    @Test
    func secondPlanFromTheSameProgramAsksFirst() async throws {
        let store = InMemoryWorkoutPlanStore()
        _ = try await makeStarter(plans: store).start(ProgramCatalog.minimum)

        let viewModel = ProgramDetailViewModel(program: ProgramCatalog.minimum, starter: makeStarter(plans: store))
        await viewModel.requestCreate()

        #expect(viewModel.asksToCreateAnother)
        #expect(viewModel.createdPlans == nil)
        #expect(store.load().count == 1)

        await viewModel.create()
        #expect(store.load().count == 2)
    }

    @Test
    func firstPlanFromAProgramIsCreatedRightAway() async {
        let store = InMemoryWorkoutPlanStore()
        _ = try? await makeStarter(plans: store).start(ProgramCatalog.skills)

        let viewModel = ProgramDetailViewModel(program: ProgramCatalog.minimum, starter: makeStarter(plans: store))
        await viewModel.requestCreate()

        #expect(viewModel.asksToCreateAnother == false)
        #expect(viewModel.createdPlans?.count == 1)
        #expect(store.load().count == 2)
    }
}
