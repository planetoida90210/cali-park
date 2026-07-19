import Foundation

// MARK: - AppEnvironment
/// Composition root: owns the single instances of app services and hands them
/// to view models through initializer injection (no global singletons).
/// Swapping a backend implementation later is a one-line change here.
@MainActor
final class AppEnvironment: ObservableObject {
    // MARK: Services
    let communityPhotoService: CommunityPhotoServiceProtocol
    let reviewsService: ReviewsServicing
    let calendarService: CalendarService
    let favoritesStore: FavoritesStoring
    let workoutLogStore: WorkoutLogStoring
    /// Persists reusable, scheduled workout plans (planner feature).
    let workoutPlanStore: WorkoutPlanStoring
    /// Schedules local reminders for scheduled plans. No UI consumer yet — the
    /// planner UI wires it in (Sprint 2 of the profile/reminders plan).
    let reminderScheduler: WorkoutReminderScheduling
    /// Persists the athlete's self-declared skill placement. Consumed by the
    /// onboarding calibration (SK4) and the Skills tab (SK5).
    let placementStore: PlacementStoring
    /// Persists which rewards have already been celebrated, so the reward loop
    /// (SK6a) stays idempotent. Consumed by the Skills tab.
    let skillProgressStore: SkillProgressStoring

    // MARK: Init
    init(communityPhotoService: CommunityPhotoServiceProtocol = InMemoryCommunityPhotoService(),
         reviewsService: ReviewsServicing = ReviewsService(),
         calendarService: CalendarService = CalendarService(),
         favoritesStore: FavoritesStoring = UserDefaultsFavoritesStore(),
         workoutLogStore: WorkoutLogStoring = FileWorkoutLogStore(),
         workoutPlanStore: WorkoutPlanStoring = FileWorkoutPlanStore(),
         reminderScheduler: WorkoutReminderScheduling = NotificationCenterReminderScheduler(),
         placementStore: PlacementStoring = FileSkillPlacementStore(),
         skillProgressStore: SkillProgressStoring = FileSkillProgressStore()) {
        self.communityPhotoService = communityPhotoService
        self.reviewsService = reviewsService
        self.calendarService = calendarService
        self.favoritesStore = favoritesStore
        self.workoutLogStore = workoutLogStore
        self.workoutPlanStore = workoutPlanStore
        self.reminderScheduler = reminderScheduler
        self.placementStore = placementStore
        self.skillProgressStore = skillProgressStore
    }

    // MARK: View Model Factories
    /// Keeps the dependency wiring for each view model in one place.
    func makeParksViewModel() -> ParksViewModel {
        ParksViewModel(favoritesStore: favoritesStore)
    }

    func makeReviewsViewModel(parkID: UUID) -> ParkReviewsViewModel {
        ParkReviewsViewModel(parkID: parkID, service: reviewsService)
    }

    func makePhotosViewModel(parkID: UUID) -> ParkPhotosViewModel {
        ParkPhotosViewModel(parkID: parkID, service: communityPhotoService)
    }

    func makeEventsViewModel(parkID: UUID) -> ParkEventsViewModel {
        ParkEventsViewModel(parkID: parkID, calendarService: calendarService)
    }

    func makeExerciseLibraryViewModel() -> ExerciseLibraryViewModel {
        ExerciseLibraryViewModel()
    }

    /// Placement questionnaire for onboarding and in-app re-calibration.
    func makePlacementCalibrationViewModel() -> PlacementCalibrationViewModel {
        PlacementCalibrationViewModel(store: placementStore)
    }

    /// Skills tab: per-path progress from logs and placement, plus the reward
    /// loop (celebrations, XP toast, badges) backed by the progress store.
    func makeSkillPathsViewModel() -> SkillPathsViewModel {
        SkillPathsViewModel(
            logStore: workoutLogStore,
            placementStore: placementStore,
            progressStore: skillProgressStore
        )
    }

    func makeWorkoutLogViewModel(exercise: Exercise) -> WorkoutLogViewModel {
        WorkoutLogViewModel(exercise: exercise, store: workoutLogStore)
    }

    func makeWorkoutHistoryViewModel() -> WorkoutHistoryViewModel {
        WorkoutHistoryViewModel(store: workoutLogStore)
    }

    func makeQuickWorkoutViewModel() -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(store: workoutLogStore)
    }

    func makeHomeDashboardViewModel() -> HomeDashboardViewModel {
        HomeDashboardViewModel(store: workoutLogStore, planStore: workoutPlanStore)
    }

    func makeWorkoutPlansViewModel() -> WorkoutPlansViewModel {
        WorkoutPlansViewModel(store: workoutPlanStore)
    }

    /// `plan == nil` starts a new plan; pass an existing plan to edit it.
    func makePlanEditorViewModel(plan: WorkoutPlan? = nil) -> PlanEditorViewModel {
        PlanEditorViewModel(plan: plan, store: workoutPlanStore)
    }

    // MARK: Preview
    static let preview = AppEnvironment()
}

// MARK: - Seeded preview environments
extension AppEnvironment {
    /// A preview environment backed by in-memory stores seeded with the given
    /// logs and plans, so the whole `HomeView` can be eyeballed in each hero
    /// state without touching disk.
    static func seeded(logs: [WorkoutLogEntry] = [],
                       plans: [WorkoutPlan] = [],
                       placement: SkillPlacement? = nil) -> AppEnvironment {
        AppEnvironment(
            workoutLogStore: InMemoryWorkoutLogStore(initial: logs),
            workoutPlanStore: InMemoryWorkoutPlanStore(initial: plans),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            skillProgressStore: InMemorySkillProgressStore()
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
                schedule: .once(.now)
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
