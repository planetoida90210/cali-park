import Foundation
@testable import cali_park

// MARK: - HomeHarness
/// Home wired the way `AppEnvironment` wires it, over the given stores, on a
/// pinned calendar and clock: the dashboard, plus the quick workouts its rail
/// and hero open. Those come from `AppEnvironment`'s factories in the app;
/// here they share the dashboard's journal, progress and clock, so a session
/// finishes at Home's "now".
@MainActor
struct HomeHarness {
    let journal: TrainingJournal
    let progress: ProgressService
    let dashboard: HomeDashboardViewModel
    let clock: () -> Date

    init(logStore: WorkoutLogStoring = InMemoryWorkoutLogStore(),
         planStore: WorkoutPlanStoring = InMemoryWorkoutPlanStore(),
         placementStore: SkillPlacementStoring = InMemorySkillPlacementStore(),
         goalStore: WeeklyGoalStoring = InMemoryWeeklyGoalStore(),
         calendar: Calendar,
         clock: @escaping () -> Date) {
        let journal = TrainingJournal(store: logStore)
        let planService = WorkoutPlanService.testing(planStore)
        let progress = ProgressService(journal: journal, placementStore: placementStore,
                                       calendar: calendar, clock: clock)
        let goals = WeeklyGoalService(journal: journal, store: goalStore, planService: planService,
                                      calendar: calendar, clock: clock)
        self.journal = journal
        self.progress = progress
        self.clock = clock
        dashboard = HomeDashboardViewModel(journal: journal, planService: planService, progress: progress,
                                           goals: goals, calendar: calendar, clock: clock)
        // The init reads nothing; `HomeView` reloads on appear.
        dashboard.reload()
    }

    /// The rail's "Szybki trening".
    func makeQuickWorkoutViewModel() -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(journal: journal, clock: clock)
    }

    /// The hero's or "Następny trening"'s "Rozpocznij" for `plan`.
    func makeQuickWorkoutViewModel(plan: WorkoutPlan) -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(journal: journal, plan: plan, progress: progress, clock: clock)
    }
}
