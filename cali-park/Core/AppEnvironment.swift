import CoreLocation
import Foundation

// MARK: - AppEnvironment
/// Composition root: owns the single instances of app services and hands them
/// to view models through initializer injection (no global singletons).
/// Swapping a backend implementation later is a one-line change here.
@MainActor
final class AppEnvironment: ObservableObject {
    // MARK: Services
    /// Read-only Parks: the bundled OSM snapshot today, the backend later.
    let parkDirectory: ParkDirectory
    /// The user's position for distances to Parks; never stored.
    let locationProvider: LocationProviding
    /// The training journal: the only write path for workout logs. Every
    /// change rescores progress (and the reward loop) and re-syncs plan
    /// reminders (a plan done today gets no reminder today), so every view
    /// model gets this one instance.
    let journal: TrainingJournal
    /// Progress (path states, XP, level, badges) computed once per journal
    /// revision and placement change, shared by Skills, Home and programs.
    let progressService: ProgressService
    /// The weekly goal (current week, streak, met goals to celebrate), read
    /// from the journal. Shared by Home and the reward overlay.
    let weeklyGoalService: WeeklyGoalService
    /// The one queue of celebrations (rungs, levels, met weekly goals) and XP
    /// toasts, whichever screen logged.
    let rewardCenter: RewardCenter
    /// Persists reusable, scheduled workout plans (planner feature).
    let workoutPlanStore: WorkoutPlanStoring
    /// Schedules local reminders for scheduled plans. Only `workoutPlanService`
    /// talks to it.
    let reminderScheduler: WorkoutReminderScheduling
    /// Owns saving and deleting plans and keeps their reminders in sync. View
    /// models change plans only through it.
    let workoutPlanService: WorkoutPlanService
    /// Persists the athlete's self-declared skill placement. Consumed by the
    /// onboarding calibration (SK4) and the Skills tab (SK5).
    let placementStore: PlacementStoring
    /// Persists which rewards have already been celebrated, so the reward loop
    /// (SK6a) stays idempotent. Only `rewardCenter` talks to it.
    let skillProgressStore: SkillProgressStoring
    /// Persists the weekly goal: goal versions, pauses and shown celebrations.
    /// Read by Home (hero ring, "Cel tygodniowy") and the goal editor.
    let weeklyGoalStore: WeeklyGoalStoring
    /// Which Home modules are shown and in what order, shared by Home and
    /// its module selection screen.
    let modulePreferences: ModulePreferences

    // MARK: Init
    /// Every store is passed explicitly: the app's file stores come from
    /// `live()`, tests and previews pass in-memory ones.
    init(parkDirectory: ParkDirectory = BundledParkDirectory(),
         locationProvider: LocationProviding? = nil,
         workoutLogStore: WorkoutLogStoring,
         workoutPlanStore: WorkoutPlanStoring,
         reminderScheduler: WorkoutReminderScheduling = NotificationCenterReminderScheduler(center: SystemNotificationCenter()),
         reminderRefreshScheduler: ReminderRefreshScheduling = AppRefreshScheduler(),
         placementStore: PlacementStoring,
         skillProgressStore: SkillProgressStoring,
         weeklyGoalStore: WeeklyGoalStoring,
         defaults: UserDefaults) {
        self.parkDirectory = parkDirectory
        // Built here: a main-actor default argument can't be evaluated in the
        // caller's nonisolated context.
        self.locationProvider = locationProvider ?? CoreLocationProvider()
        self.workoutPlanStore = workoutPlanStore
        self.reminderScheduler = reminderScheduler
        // The plan service only reads the log, to skip days already done.
        let planService = WorkoutPlanService(store: workoutPlanStore,
                                             logStore: workoutLogStore,
                                             scheduler: reminderScheduler,
                                             refreshScheduler: reminderRefreshScheduler)
        self.workoutPlanService = planService
        let journal = TrainingJournal(store: workoutLogStore)
        journal.onChange { [weak planService] in
            Task { await planService?.syncReminders() }
        }
        self.journal = journal
        let progress = ProgressService(journal: journal, placementStore: placementStore)
        self.progressService = progress
        let goals = WeeklyGoalService(journal: journal, store: weeklyGoalStore, planService: planService)
        self.weeklyGoalService = goals
        self.rewardCenter = RewardCenter(progress: progress, store: skillProgressStore, goals: goals)
        self.placementStore = placementStore
        self.skillProgressStore = skillProgressStore
        self.weeklyGoalStore = weeklyGoalStore
        self.modulePreferences = ModulePreferences(defaults: defaults)
    }

    // MARK: View Model Factories
    /// Keeps the dependency wiring for each view model in one place.
    /// Parks tab: map and list of Parks.
    func makeParkMapViewModel() -> ParkMapViewModel {
        ParkMapViewModel(directory: parkDirectory, location: locationProvider)
    }

    /// Home module with the nearest Park.
    func makeNearestParkViewModel() -> NearestParkViewModel {
        NearestParkViewModel(directory: parkDirectory, location: locationProvider)
    }

    func makeExerciseLibraryViewModel() -> ExerciseLibraryViewModel {
        ExerciseLibraryViewModel()
    }

    /// Placement questionnaire for onboarding and in-app re-calibration.
    /// Saving re-reads the placement into shared progress.
    func makePlacementCalibrationViewModel() -> PlacementCalibrationViewModel {
        PlacementCalibrationViewModel(store: placementStore, onSave: { [progressService] in
            progressService.reloadPlacement()
        })
    }

    /// Skills tab: per-path progress from the shared snapshot. Rewards live
    /// in `rewardCenter`.
    func makeSkillPathsViewModel() -> SkillPathsViewModel {
        SkillPathsViewModel(progress: progressService)
    }

    func makeWorkoutLogViewModel(exercise: Exercise) -> WorkoutLogViewModel {
        WorkoutLogViewModel(exercise: exercise, journal: journal)
    }

    func makeWorkoutHistoryViewModel() -> WorkoutHistoryViewModel {
        WorkoutHistoryViewModel(journal: journal)
    }

    func makeWorkoutSessionDetailViewModel(sessionID: UUID) -> WorkoutSessionDetailViewModel {
        WorkoutSessionDetailViewModel(sessionID: sessionID, journal: journal)
    }

    func makeQuickWorkoutViewModel() -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(journal: journal)
    }

    func makeHomeDashboardViewModel() -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            journal: journal,
            planService: workoutPlanService,
            progress: progressService,
            goals: weeklyGoalService
        )
    }

    /// The weekly goal editor (goals and pause), shared by Home and Profile.
    func makeWeeklyGoalEditorViewModel() -> WeeklyGoalEditorViewModel {
        WeeklyGoalEditorViewModel(store: weeklyGoalStore, journal: journal)
    }

    func makeWorkoutPlansViewModel() -> WorkoutPlansViewModel {
        WorkoutPlansViewModel(service: workoutPlanService)
    }

    /// `plan == nil` starts a new plan; pass an existing plan to edit it.
    func makePlanEditorViewModel(plan: WorkoutPlan? = nil) -> PlanEditorViewModel {
        PlanEditorViewModel(plan: plan, service: workoutPlanService)
    }

    /// Creates a ready-made program's plans on the athlete's current rungs.
    func makeProgramStarter() -> ProgramStarter {
        ProgramStarter(planService: workoutPlanService, progress: progressService)
    }

    /// Detail screen of one ready-made program, with "Utwórz plan".
    func makeProgramDetailViewModel(program: TrainingProgram) -> ProgramDetailViewModel {
        ProgramDetailViewModel(program: program, starter: makeProgramStarter())
    }

    /// Onboarding's program suggestion after the level test.
    func makeProgramChoiceViewModel() -> ProgramChoiceViewModel {
        ProgramChoiceViewModel(starter: makeProgramStarter())
    }

    /// First-run flow: level test, program choice and weekly goal.
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            calibration: makePlacementCalibrationViewModel(),
            programChoice: makeProgramChoiceViewModel(),
            goalStore: weeklyGoalStore,
            goals: weeklyGoalService,
            journal: journal
        )
    }

    /// Profile tab: statistics and the weekly goal summary.
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(journal: journal, progress: progressService, goals: weeklyGoalService)
    }

    /// Reads and replaces everything the athlete owns (export and import).
    func makeTrainingBackupService() -> TrainingBackupService {
        TrainingBackupService(
            journal: journal,
            planStore: workoutPlanStore,
            placementStore: placementStore,
            progressStore: skillProgressStore,
            goalStore: weeklyGoalStore,
            planService: workoutPlanService,
            progress: progressService,
            goals: weeklyGoalService,
            rewards: rewardCenter
        )
    }

    /// "Eksport i import treningów" in Profile.
    func makeTrainingBackupViewModel() -> TrainingBackupViewModel {
        TrainingBackupViewModel(service: makeTrainingBackupService())
    }

    // MARK: Live
    /// The app's environment over the real file stores. First moves the store
    /// files from Documents to Application Support (and deletes the old Core
    /// Data scaffold's files), so it runs before any store loads.
    static func live() -> AppEnvironment {
        CoreDataScaffoldCleanup().run()
        let locations = StoreDirectoryMigration.live().run()
        return AppEnvironment(
            workoutLogStore: FileWorkoutLogStore(directory: locations.directory(for: .workoutLog)),
            workoutPlanStore: FileWorkoutPlanStore(directory: locations.directory(for: .workoutPlans)),
            placementStore: FileSkillPlacementStore(directory: locations.directory(for: .skillPlacement)),
            skillProgressStore: FileSkillProgressStore(directory: locations.directory(for: .skillProgress)),
            weeklyGoalStore: FileWeeklyGoalStore(directory: locations.directory(for: .weeklyGoal)),
            defaults: .standard
        )
    }

    // MARK: Preview
    /// Backed by the real file stores; prefer `seeded(...)` in previews.
    static let preview = AppEnvironment.live()
}

// MARK: - Throwaway defaults
extension UserDefaults {
    /// A fresh, empty suite with a unique name, for previews and tests. It
    /// writes nothing to disk until something is set in it.
    static func throwaway() -> UserDefaults {
        let name = "cali-park.throwaway.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            // Only the app's own bundle ID and the global domain are refused.
            preconditionFailure("UserDefaults refused the suite \(name)")
        }
        return defaults
    }
}

// MARK: - Seeded preview environments
extension AppEnvironment {
    /// A preview environment backed by in-memory stores seeded with the given
    /// logs and plans, so the whole `HomeView` can be eyeballed in each hero
    /// state without touching disk. Parks are the real bundled snapshot; the
    /// location is a fixed point (central Warsaw) so previews never prompt.
    /// Home module preferences live in a throwaway `UserDefaults` suite, so
    /// previews and tests never read or change the real ones.
    static func seeded(logs: [WorkoutLogEntry] = [],
                       plans: [WorkoutPlan] = [],
                       placement: SkillPlacement? = nil,
                       weeklyGoal: WeeklyGoalHistory? = nil,
                       location: LocationProviding? = nil) -> AppEnvironment {
        AppEnvironment(
            parkDirectory: BundledParkDirectory(),
            locationProvider: location ?? FixedLocationProvider(
                authorization: .authorized,
                location: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)
            ),
            workoutLogStore: InMemoryWorkoutLogStore(initial: logs),
            workoutPlanStore: InMemoryWorkoutPlanStore(initial: plans),
            reminderScheduler: InMemoryReminderScheduler(status: .authorized),
            reminderRefreshScheduler: InMemoryReminderRefreshScheduler(),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            skillProgressStore: InMemorySkillProgressStore(),
            weeklyGoalStore: InMemoryWeeklyGoalStore(initial: weeklyGoal),
            defaults: .throwaway()
        )
    }

    /// Plan scheduled for today, nothing logged yet → hero shows "Rozpocznij".
    static var previewPlanToday: AppEnvironment {
        seeded(plans: [
            WorkoutPlan(
                name: "Push Day",
                exercises: [
                    PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 12),
                    PlannedExercise(exerciseID: ExerciseCatalog.dipsID, targetSets: 3, targetReps: 10)
                ],
                schedule: .once(CalendarDay(.now, in: .current))
            )
        ])
    }

    /// A whole session logged today → hero shows the day's summary.
    static var previewCompletedToday: AppEnvironment {
        let session = UUID()
        return seeded(logs: [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)],
                sessionID: session
            ),
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.dipsID,
                sets: [LoggedSet(reps: 12)],
                sessionID: session
            )
        ])
    }

    /// No plans and an empty journal → hero invites the first workout.
    static var previewEmpty: AppEnvironment { seeded() }

    /// A seasoned athlete for the Skills tab: several dynamic ladders finished
    /// through logs, plus a mid-ladder static (front lever conquered through the
    /// advanced tuck). Exercises the conquered / current / future rung states.
    static var skillsVeteran: AppEnvironment {
        func timed(_ id: UUID, seconds: Int, holds: Int = 3) -> WorkoutLogEntry {
            WorkoutLogEntry(exerciseID: id, sets: Array(repeating: LoggedSet(reps: 1, durationSeconds: seconds), count: holds))
        }
        func reps(_ id: UUID, reps: Int, sets: Int = 3) -> WorkoutLogEntry {
            WorkoutLogEntry(exerciseID: id, sets: Array(repeating: LoggedSet(reps: reps), count: sets))
        }
        return seeded(
            logs: [
                reps(ExerciseCatalog.archerPullUpsID, reps: 5),
                reps(ExerciseCatalog.pseudoPlanchePushUpsID, reps: 8),
                reps(ExerciseCatalog.ringDipsID, reps: 8),
                timed(ExerciseCatalog.tuckFrontLeverID, seconds: 20),
                timed(ExerciseCatalog.advancedTuckFrontLeverID, seconds: 20),
                timed(ExerciseCatalog.straddleFrontLeverID, seconds: 12)
            ],
            placement: SkillPlacement(declaredRungByPath: [.core: 2, .legs: 3])
        )
    }
}
