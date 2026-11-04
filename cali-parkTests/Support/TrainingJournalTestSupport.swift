import Foundation
@testable import cali_park

// MARK: - TrainingStack
/// The journal → progress → rewards chain over the given stores, wired the way
/// `AppEnvironment` wires it, for tests that look at progress or rewards.
@MainActor
struct TrainingStack {
    let journal: TrainingJournal
    let progress: ProgressService
    let rewards: RewardCenter

    init(logStore: WorkoutLogStoring = InMemoryWorkoutLogStore(),
         placementStore: PlacementStoring = InMemorySkillPlacementStore(),
         progressStore: SkillProgressStoring = InMemorySkillProgressStore()) {
        journal = TrainingJournal(store: logStore)
        progress = ProgressService(journal: journal, placementStore: placementStore)
        rewards = RewardCenter(progress: progress, store: progressStore, goals: nil)
    }

    func skillPaths() -> SkillPathsViewModel {
        SkillPathsViewModel(progress: progress)
    }

    /// Dismisses celebrations until the queue is empty; returns how many.
    @discardableResult
    func drainCelebrations() -> Int {
        var shown = 0
        while rewards.currentCelebration != nil, shown < 100 {
            rewards.dismissCurrentCelebration()
            shown += 1
        }
        return shown
    }
}

// MARK: - Store-based conveniences
// Tests that only care about one screen build it over a store; each gets its
// own journal over that store, like a fresh launch.

@MainActor
extension WorkoutLogViewModel {
    convenience init(exercise: Exercise, store: WorkoutLogStoring) {
        self.init(exercise: exercise, journal: TrainingJournal(store: store))
    }
}

@MainActor
extension QuickWorkoutViewModel {
    convenience init(store: WorkoutLogStoring) {
        self.init(journal: TrainingJournal(store: store))
    }

    convenience init(store: WorkoutLogStoring,
                     plan: WorkoutPlan,
                     pathStates: [ProgressionPathID: PathState]? = nil,
                     logs: [WorkoutLogEntry] = []) {
        self.init(journal: TrainingJournal(store: store), plan: plan, pathStates: pathStates, logs: logs)
    }
}

@MainActor
extension WorkoutHistoryViewModel {
    convenience init(store: WorkoutLogStoring) {
        self.init(journal: TrainingJournal(store: store))
    }
}

@MainActor
extension WorkoutSessionDetailViewModel {
    convenience init(sessionID: UUID, store: WorkoutLogStoring) {
        self.init(sessionID: sessionID, journal: TrainingJournal(store: store))
    }
}

@MainActor
extension HomeDashboardViewModel {
    convenience init(store: WorkoutLogStoring,
                     planService: WorkoutPlanService,
                     placementStore: PlacementStoring = InMemorySkillPlacementStore(),
                     goalStore: WeeklyGoalStoring = InMemoryWeeklyGoalStore(),
                     calendar: Calendar = .current,
                     clock: @escaping () -> Date = { .now }) {
        let journal = TrainingJournal(store: store)
        self.init(journal: journal,
                  planService: planService,
                  progress: ProgressService(journal: journal, placementStore: placementStore, calendar: calendar, clock: clock),
                  goals: WeeklyGoalService(journal: journal, store: goalStore, planService: planService,
                                           calendar: calendar, clock: clock),
                  calendar: calendar,
                  clock: clock)
        // The init reads nothing; `HomeView` reloads on appear.
        reload()
    }
}

@MainActor
extension WeeklyGoalEditorViewModel {
    convenience init(store: WeeklyGoalStoring,
                     logStore: WorkoutLogStoring,
                     calendar: Calendar = .current,
                     clock: @escaping () -> Date = { .now }) {
        self.init(store: store, journal: TrainingJournal(store: logStore), calendar: calendar, clock: clock)
    }
}

@MainActor
extension ProgramStarter {
    convenience init(planService: WorkoutPlanService,
                     logStore: WorkoutLogStoring,
                     placementStore: PlacementStoring,
                     clock: @escaping () -> Date = { .now }) {
        let journal = TrainingJournal(store: logStore)
        self.init(planService: planService,
                  progress: ProgressService(journal: journal, placementStore: placementStore),
                  clock: clock)
    }
}
