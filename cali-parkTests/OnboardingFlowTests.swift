import Foundation
import Testing

@testable import cali_park

// MARK: - Rig
/// An onboarding view model over in-memory stores shared by the level test,
/// the program starter and the weekly goal, on a fixed clock.
@MainActor
private struct OnboardingRig {
    let placementStore = InMemorySkillPlacementStore()
    let planStore: WorkoutPlanStoring
    let goalStore: WeeklyGoalStoring
    let logStore = InMemoryWorkoutLogStore()
    let viewModel: OnboardingViewModel

    init(
        planStore: WorkoutPlanStoring = InMemoryWorkoutPlanStore(),
        goalStore: WeeklyGoalStoring = InMemoryWeeklyGoalStore()
    ) {
        self.planStore = planStore
        self.goalStore = goalStore
        let journal = TrainingJournal(store: logStore)
        let progress = ProgressService(
            journal: journal, placementStore: placementStore,
            calendar: ProgramFixtures.calendar, clock: { ProgramFixtures.today })
        let starter = ProgramStarter(
            planService: .testing(planStore, logStore: logStore), progress: progress,
            clock: { ProgramFixtures.today })
        viewModel = OnboardingViewModel(
            calibration: PlacementCalibrationViewModel(
                store: placementStore, now: { ProgramFixtures.today },
                onSave: { progress.reloadPlacement() }),
            programChoice: ProgramChoiceViewModel(starter: starter),
            goalStore: goalStore,
            goals: nil,
            journal: journal,
            calendar: ProgramFixtures.calendar,
            clock: { ProgramFixtures.today }
        )
    }

    /// Answers "0" to the pull-up question of the level test.
    func answerZeroPullUps() throws {
        let question = try #require(viewModel.calibration.repQuestions.first { $0.path == .pullUp })
        viewModel.calibration.select(.none, for: question)
    }

    func walkToGoalStep() {
        while !viewModel.page.isLast { viewModel.goForward() }
    }
}

// MARK: - Tests
@MainActor
@Suite("Onboarding flow", .timeLimit(.minutes(1)))
struct OnboardingFlowTests {
    @Test("The steps are welcome, level test, program, weekly goal")
    func steps() {
        #expect(OnboardingPage.allCases == [.welcome, .placement, .program, .weeklyGoal])
        let rig = OnboardingRig()
        #expect(rig.viewModel.page == .welcome)
        rig.viewModel.goBack()
        #expect(rig.viewModel.page == .welcome)
        rig.walkToGoalStep()
        #expect(rig.viewModel.page == .weeklyGoal)
        rig.viewModel.goForward()
        #expect(rig.viewModel.page == .weeklyGoal)
    }

    @Test("Reaching the program step suggests a program from the level test")
    func programSuggestion() throws {
        let rig = OnboardingRig()
        try rig.answerZeroPullUps()

        rig.viewModel.show(.program)

        #expect(rig.viewModel.programChoice.choice == .program(.firstPullUp))
    }

    @Test(
        "The goal's days follow the chosen program, 3 without one",
        arguments: [
            (ProgramChoiceViewModel.Choice.program(.fundamentals), 3),
            (.program(.skills), 2),
            (.program(.minimum), 3),
            (.none, 3)
        ])
    func daysFollowProgram(choice: ProgramChoiceViewModel.Choice, days: Int) {
        let rig = OnboardingRig()
        rig.viewModel.programChoice.pick(choice)

        rig.viewModel.show(.weeklyGoal)

        #expect(rig.viewModel.trainingDays == days)
        #expect(rig.viewModel.suggestedTrainingDays == days)
    }

    @Test("Days the athlete set are kept when the program changes")
    func editedDaysStick() {
        let rig = OnboardingRig()
        rig.viewModel.show(.weeklyGoal)
        rig.viewModel.setTrainingDays(5)

        rig.viewModel.show(.program)
        rig.viewModel.programChoice.pick(.program(.skills))
        rig.viewModel.show(.weeklyGoal)

        #expect(rig.viewModel.trainingDays == 5)
    }

    @Test("Days are clamped to 1–7")
    func daysClamped() {
        let rig = OnboardingRig()
        rig.viewModel.setTrainingDays(9)
        #expect(rig.viewModel.trainingDays == 7)
        rig.viewModel.setTrainingDays(0)
        #expect(rig.viewModel.trainingDays == 1)
    }

    @Test("Finishing saves the placement, the program's plans on the declared rungs, and the goal")
    func finishSavesEverything() async throws {
        let rig = OnboardingRig()
        try rig.answerZeroPullUps()
        rig.viewModel.show(.program)
        rig.viewModel.show(.weeklyGoal)
        rig.viewModel.setTrainingDays(4)

        #expect(await rig.viewModel.finish())

        #expect(rig.viewModel.errorMessage == nil)
        #expect(rig.placementStore.load()?.declaredStepByPath[.pullUp] == ExerciseCatalog.negativePullUpsID)
        let plans = try rig.planStore.load()
        #expect(plans.map(\.programID) == ["firstPullUp"])
        // The placement was saved first, so the plan starts on the declared rung.
        #expect(plans.first?.exercises.first?.exerciseID == ExerciseCatalog.negativePullUpsID)
        let goal = try #require(try rig.goalStore.load())
        #expect(goal.currentGoals(at: ProgramFixtures.today) == WeeklyGoal.defaultGoals(trainingDaysPerWeek: 4))
    }

    @Test("Without a program, finishing creates no plan and saves 3 days")
    func finishWithoutProgram() async throws {
        let rig = OnboardingRig()
        rig.viewModel.programChoice.pick(.none)
        rig.walkToGoalStep()

        #expect(await rig.viewModel.finish())

        #expect(try rig.planStore.load().isEmpty)
        let goal = try #require(try rig.goalStore.load())
        #expect(goal.currentGoals(at: ProgramFixtures.today) == WeeklyGoal.defaultGoals(trainingDaysPerWeek: 3))
    }

    @Test("A goal that cannot be saved is reported, and the plans are still created")
    func goalFailure() async throws {
        let rig = OnboardingRig(goalStore: ReadOnlyWeeklyGoalStore())
        rig.walkToGoalStep()

        #expect(await rig.viewModel.finish() == false)

        #expect(rig.viewModel.errorMessage?.contains("celu tygodniowego") == true)
        #expect(Set(try rig.planStore.load().map(\.programID)) == ["fundamentals"])
    }

    @Test("A program that cannot be created is reported, and the goal is still saved")
    func programFailure() async throws {
        let goalStore = InMemoryWeeklyGoalStore()
        let rig = OnboardingRig(planStore: ReadOnlyPlanStore(), goalStore: goalStore)
        rig.viewModel.programChoice.pick(.program(.skills))
        rig.walkToGoalStep()

        #expect(await rig.viewModel.finish() == false)

        #expect(rig.viewModel.errorMessage?.contains("Skille") == true)
        #expect(rig.viewModel.programChoice.errorMessage == nil)
        #expect(goalStore.saveCount == 1)
    }

    @Test("The level test no longer asks about a band, and keeps one declared earlier")
    func bandKeptWithoutQuestion() throws {
        let store = InMemorySkillPlacementStore(initial: SkillPlacement(ownedEquipment: [PlacementCalibration.bandEquipment]))
        let calibration = PlacementCalibrationViewModel(store: store, now: { ProgramFixtures.today })
        let question = try #require(calibration.repQuestions.first { $0.path == .pullUp })
        calibration.select(.few, for: question)

        calibration.save()

        #expect(store.load()?.ownsEquipment(PlacementCalibration.bandEquipment) == true)
    }
}
