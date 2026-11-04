//
//  WeeklyGoalEditorTests.swift
//  cali-parkTests
//
//  Ticket 027: the goal editor view model (draft, primary, save, pause, load
//  failure) and the weekly goal on Home (snapshot, celebration, errors).
//

import Foundation
import Testing
@testable import cali_park

private typealias F = WeeklyGoalFixtures

// MARK: - Editor

@MainActor
struct WeeklyGoalEditorViewModelTests {
    private func editor(store: WeeklyGoalStoring = InMemoryWeeklyGoalStore(),
                        logs: [WorkoutLogEntry] = [],
                        now: Date = F.day(2)) -> WeeklyGoalEditorViewModel {
        let viewModel = WeeklyGoalEditorViewModel(store: store, logStore: InMemoryWorkoutLogStore(initial: logs),
                                                  calendar: F.calendar, clock: { now })
        // The editor sheet loads when it appears.
        viewModel.load()
        return viewModel
    }

    /// The editor is built on demand by Home and Profile; building it must
    /// not touch the store, only the sheet's appearance does (F-7).
    @Test
    func initReadsNothingUntilLoad() {
        let store = CountingWeeklyGoalStore(initial: WeeklyGoalHistory.empty)
        let viewModel = WeeklyGoalEditorViewModel(store: store, logStore: InMemoryWorkoutLogStore(),
                                                  calendar: F.calendar, clock: { F.day(2) })
        #expect(store.loadCount == 0)
        #expect(viewModel.hasLoaded == false)

        viewModel.load()
        #expect(store.loadCount == 1)
        #expect(viewModel.goals == WeeklyGoal.defaultGoals)
    }

    /// Coming back from a goal's detail screen shows the editor again; the
    /// second `load()` must not read over the draft.
    @Test
    func loadRunsOnceAndKeepsTheDraft() {
        let store = CountingWeeklyGoalStore(initial: nil)
        let viewModel = editor(store: store)
        viewModel.addGoal(.plannedWorkouts)

        viewModel.load()

        #expect(store.loadCount == 1)
        #expect(viewModel.goals.count == WeeklyGoal.defaultGoals.count + 1)
        #expect(viewModel.hasUnsavedChanges)
    }

    @Test
    func nothingSavedShowsTheDefaultAndWritesNothing() {
        let store = InMemoryWeeklyGoalStore()
        let viewModel = editor(store: store)

        #expect(viewModel.goals == WeeklyGoal.defaultGoals)
        #expect(viewModel.isDefault)
        #expect(viewModel.hasUnsavedChanges == false)
        #expect(viewModel.save())
        #expect(store.saveCount == 0)
    }

    @Test
    func atMostThreeGoals() {
        let viewModel = editor()
        #expect(viewModel.addGoal(.plannedWorkouts) != nil)
        #expect(viewModel.addGoal(.exerciseVolume) != nil)
        #expect(viewModel.canAddGoal == false)
        #expect(viewModel.addGoal(.trainingDays) == nil)
        #expect(viewModel.goals.map(\.metric.kind) == [.trainingDays, .plannedWorkouts, .exerciseVolume])
    }

    @Test
    func removingThePrimaryPromotesTheNextAndKeepsOne() throws {
        let viewModel = editor()
        let added = try #require(viewModel.addGoal(.plannedWorkouts))
        viewModel.removeGoal(WeeklyGoal.defaultGoalID)
        #expect(viewModel.goals.map(\.id) == [added])
        #expect(viewModel.isPrimary(added))

        viewModel.removeGoal(added)
        #expect(viewModel.goals.map(\.id) == [added])
        #expect(viewModel.canRemoveGoals == false)
    }

    @Test
    func makePrimaryMovesTheGoalFirst() throws {
        let viewModel = editor()
        let volume = try #require(viewModel.addGoal(.exerciseVolume))
        viewModel.makePrimary(volume)
        #expect(viewModel.goals.map(\.id) == [volume, WeeklyGoal.defaultGoalID])
    }

    @Test
    func outOfRangeTargetsAreIgnored() {
        let viewModel = editor()
        viewModel.updateMetric(.trainingDays(days: 9), forGoal: WeeklyGoal.defaultGoalID)
        #expect(viewModel.goals == WeeklyGoal.defaultGoals)
        viewModel.updateMetric(.trainingDays(days: 5), forGoal: WeeklyGoal.defaultGoalID)
        #expect(viewModel.goals.first?.metric == .trainingDays(days: 5))
        #expect(viewModel.hasUnsavedChanges)
    }

    /// The first save keeps the default from the first workout, then the new
    /// goals from now.
    @Test
    func saveWritesTheDefaultHistoryAndTheNewGoals() throws {
        let store = InMemoryWeeklyGoalStore()
        let firstWorkout = F.day(week: -3, 1)
        let viewModel = editor(store: store, logs: [F.entry(at: F.day(1)), F.entry(at: firstWorkout)])
        viewModel.updateMetric(.trainingDays(days: 4), forGoal: WeeklyGoal.defaultGoalID)

        #expect(viewModel.save())
        let saved = try #require(store.load())
        #expect(saved.versions == [
            F.version(WeeklyGoal.defaultGoals, from: firstWorkout),
            F.version([F.days(4)], from: F.day(2))
        ])
        #expect(viewModel.hasUnsavedChanges == false)
        #expect(viewModel.isDefault == false)
    }

    @Test
    func discardReturnsToTheSavedGoals() {
        let viewModel = editor()
        viewModel.addGoal(.plannedWorkouts)
        viewModel.discardChanges()
        #expect(viewModel.goals == WeeklyGoal.defaultGoals)
    }

    /// An unreadable goal file shows the shared error and never offers the
    /// default in its place.
    @Test
    func loadFailureShowsTheErrorAndBlocksEditing() {
        let viewModel = editor(store: BrokenWeeklyGoalStore())
        #expect(viewModel.errorMessage == StoreLoadFailure.message)
        #expect(viewModel.hasLoadError)
        #expect(viewModel.goals.isEmpty)
        #expect(viewModel.canEdit == false)
        #expect(viewModel.addGoal(.trainingDays) == nil)
        #expect(viewModel.save() == false)
    }

    @Test
    func failedWriteKeepsTheDraft() {
        let viewModel = editor(store: ReadOnlyWeeklyGoalStore())
        viewModel.updateMetric(.trainingDays(days: 2), forGoal: WeeklyGoal.defaultGoalID)
        #expect(viewModel.save() == false)
        #expect(viewModel.errorMessage == WeeklyGoalEditorViewModel.saveFailureMessage)
        #expect(viewModel.hasUnsavedChanges)
    }

    @Test
    func weekPauseStartsTodayAndEndsInAWeek() throws {
        let store = InMemoryWeeklyGoalStore()
        let viewModel = editor(store: store, now: F.day(2, hour: 15))
        viewModel.startPause(.week)

        let pause = try #require(viewModel.activePause)
        #expect(pause.start == F.day(2, hour: 0))
        #expect(pause.plannedEnd == F.day(9, hour: 0))
        #expect(store.load()?.pauses == [pause])
        #expect(store.load()?.versions.isEmpty == true) // the goal stays the default

        viewModel.endPause()
        #expect(viewModel.activePause == nil)
        #expect(store.load()?.pauses.first?.endedAt == F.day(2, hour: 15))
    }

    @Test
    func monthAndCustomPauses() throws {
        let month = editor(now: F.day(2))
        month.startPause(.month)
        #expect(month.activePause?.plannedEnd == F.date(2026, 12, 4, 0))

        let custom = editor(now: F.day(2))
        #expect(custom.customPauseRange == F.day(2, hour: 0)...F.date(2027, 2, 1, 0))
        custom.startPause(.through(F.day(5, hour: 18)))
        #expect(custom.activePause?.plannedEnd == F.day(6, hour: 0))
    }

    @Test
    func pauseIsBlockedWhenTheGoalCannotBeRead() {
        let viewModel = editor(store: BrokenWeeklyGoalStore())
        viewModel.startPause(.week)
        #expect(viewModel.activePause == nil)
    }
}

// MARK: - Home

@MainActor
struct HomeWeeklyGoalTests {
    private func dashboard(goalStore: WeeklyGoalStoring,
                           entries: [WorkoutLogEntry],
                           now: Date = F.day(3)) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: entries),
            planService: .testing(InMemoryWorkoutPlanStore()),
            placementStore: InMemorySkillPlacementStore(),
            goalStore: goalStore,
            calendar: F.calendar,
            clock: { now }
        )
    }

    private func goals(goalStore: WeeklyGoalStoring,
                       entries: [WorkoutLogEntry],
                       now: Date = F.day(3)) -> WeeklyGoalService {
        WeeklyGoalService(
            journal: TrainingJournal(store: InMemoryWorkoutLogStore(initial: entries)),
            store: goalStore,
            planService: .testing(InMemoryWorkoutPlanStore()),
            calendar: F.calendar,
            clock: { now }
        )
    }

    @Test
    func homeShowsTheSavedPrimaryGoal() throws {
        let volume = F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 30))
        let store = InMemoryWeeklyGoalStore(initial: WeeklyGoalHistory(versions: [
            F.version([volume, F.days(2)], from: F.day(week: -2, hour: 0))
        ]))
        let home = dashboard(goalStore: store, entries: F.trained(week: 0, days: [0, 1]))
        let goal = try #require(home.weeklyGoal)
        #expect(goal.week.primary.goal == volume)
        #expect(goal.week.primary.value == 16)
        #expect(goal.isDefault == false)
    }

    @Test
    func unreadableGoalShowsTheErrorAndNoGoal() {
        let home = dashboard(goalStore: BrokenWeeklyGoalStore(), entries: F.trained(week: 0, days: [0, 1, 2]))
        #expect(home.weeklyGoal == nil)
        #expect(home.errorMessage == StoreLoadFailure.message)
        #expect(goals(goalStore: BrokenWeeklyGoalStore(), entries: F.trained(week: 0, days: [0, 1, 2])).pendingCelebration == nil)
    }

    /// A met goal celebrates once: dismissing records it, so a new dashboard
    /// (an app relaunch) does not celebrate again.
    @Test
    func metGoalCelebratesOnce() throws {
        let store = InMemoryWeeklyGoalStore()
        let entries = F.trained(week: 0, days: [0, 1, 2])
        let service = goals(goalStore: store, entries: entries)

        let celebrated = try #require(service.pendingCelebration)
        #expect(celebrated.goal.id == WeeklyGoal.defaultGoalID)

        service.dismissCelebration()
        #expect(service.pendingCelebration == nil)
        let saved = try #require(store.load())
        #expect(saved.hasCelebrated(goalID: WeeklyGoal.defaultGoalID, weekStart: F.monday))
        #expect(saved.versions.isEmpty) // marking a celebration does not save a goal

        #expect(goals(goalStore: store, entries: entries).pendingCelebration == nil)
    }

    @Test
    func failedMarkStillHidesTheCelebrationForTheSession() {
        let service = goals(goalStore: ReadOnlyWeeklyGoalStore(), entries: F.trained(week: 0, days: [0, 1, 2]))
        #expect(service.pendingCelebration != nil)
        service.dismissCelebration()
        #expect(service.pendingCelebration == nil)
    }

    @Test
    func celebrationPresentationHasNoXP() throws {
        let service = goals(goalStore: InMemoryWeeklyGoalStore(),
                            entries: F.trained(week: -1, days: [0, 1, 2]) + F.trained(week: 0, days: [0, 1, 2]))
        let met = try #require(service.pendingCelebration)
        let presentation = CelebrationPresentation.weeklyGoalMet(met, isPrimary: true, streak: 2)
        #expect(presentation.xpNote == nil)
        #expect(presentation.title == "3 dni treningowe")
        #expect(presentation.subtitle == "Seria: 2 tygodnie")
    }
}

// MARK: - Copy

struct WeeklyGoalFormatTests {
    @Test(arguments: [(1, "1 tydzień"), (2, "2 tygodnie"), (5, "5 tygodni"), (12, "12 tygodni"), (22, "22 tygodnie")])
    func weeks(count: Int, expected: String) {
        #expect(PolishPlural.weeks(count) == expected)
    }

    @Test(arguments: [(1, "1 trening"), (3, "3 treningi"), (5, "5 treningów"), (14, "14 treningów")])
    func workouts(count: Int, expected: String) {
        #expect(PolishPlural.workouts(count) == expected)
    }

    @Test(arguments: [(1, "1 dzień treningowy"), (3, "3 dni treningowe"), (5, "5 dni treningowych")])
    func trainingDays(count: Int, expected: String) {
        #expect(PolishPlural.trainingDays(count) == expected)
    }

    @Test
    func titles() {
        #expect(WeeklyGoalFormat.title(.plannedWorkouts(target: .count(workouts: 4))) == "4 treningi z planu")
        #expect(WeeklyGoalFormat.title(.plannedWorkouts(target: .allScheduled)) == "Wszystkie zaplanowane treningi")
        let pullUps = ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)?.name ?? ""
        #expect(WeeklyGoalFormat.title(.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps,
                                                       amount: 75)) == "\(pullUps): 75 powtórzeń")
        let lSit = WeeklyGoal.Metric.exerciseVolume(exerciseID: ExerciseCatalog.lSitID, measurement: .seconds, amount: 180)
        #expect(WeeklyGoalFormat.title(lSit).hasSuffix(": 180 s".keptTogether))
        #expect(WeeklyGoalFormat.spokenTitle(lSit).hasSuffix(": 180 sekund"))
    }

    /// Row 18 of the second visual pass: "Dni treningowe" under "3 dni
    /// treningowe" said nothing new.
    @Test
    func editorSubtitleOnlyWhereItAddsToTheTitle() {
        #expect(WeeklyGoalFormat.editorSubtitle(.trainingDays(days: 3)) == nil)
        #expect(WeeklyGoalFormat.editorSubtitle(.plannedWorkouts(target: .count(workouts: 4))) == nil)
        #expect(WeeklyGoalFormat.editorSubtitle(.plannedWorkouts(target: .allScheduled)) == nil)
        let volume = WeeklyGoal.Metric.exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 75)
        #expect(WeeklyGoalFormat.editorSubtitle(volume) == "Objętość w tygodniu")
    }

    @Test
    func progressAgreesWithTheTarget() {
        let days = WeeklyGoalProgress(goal: F.days(3), target: 3, value: 2)
        #expect(WeeklyGoalFormat.progress(days) == "2 / 3 dni")
        #expect(WeeklyGoalFormat.spokenProgress(days) == "2 z 3 dni")

        let none = WeeklyGoalProgress(goal: F.goal(.plannedWorkouts(target: .allScheduled)), target: 0, value: 0)
        #expect(WeeklyGoalFormat.progress(none) == "Brak zaplanowanych treningów")

        let hold = WeeklyGoalProgress(
            goal: F.goal(.exerciseVolume(exerciseID: ExerciseCatalog.lSitID, measurement: .seconds, amount: 180)),
            target: 180, value: 60
        )
        #expect(WeeklyGoalFormat.progress(hold) == "60 / 180 s".keptTogether)
        #expect(WeeklyGoalFormat.spokenProgress(hold) == "60 z 180 sekund")
    }
}

// MARK: - Spy

/// Counts reads, to check when the editor touches the store.
private final class CountingWeeklyGoalStore: WeeklyGoalStoring {
    private var history: WeeklyGoalHistory?
    private(set) var loadCount = 0

    init(initial: WeeklyGoalHistory?) { history = initial }

    func load() -> WeeklyGoalHistory? {
        loadCount += 1
        return history
    }

    func save(_ history: WeeklyGoalHistory) throws { self.history = history }
}
