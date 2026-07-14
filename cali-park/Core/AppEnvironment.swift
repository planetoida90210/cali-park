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

    // MARK: Init
    init(communityPhotoService: CommunityPhotoServiceProtocol = InMemoryCommunityPhotoService(),
         reviewsService: ReviewsServicing = ReviewsService(),
         calendarService: CalendarService = CalendarService(),
         favoritesStore: FavoritesStoring = UserDefaultsFavoritesStore(),
         workoutLogStore: WorkoutLogStoring = FileWorkoutLogStore(),
         workoutPlanStore: WorkoutPlanStoring = FileWorkoutPlanStore(),
         reminderScheduler: WorkoutReminderScheduling = NotificationCenterReminderScheduler()) {
        self.communityPhotoService = communityPhotoService
        self.reviewsService = reviewsService
        self.calendarService = calendarService
        self.favoritesStore = favoritesStore
        self.workoutLogStore = workoutLogStore
        self.workoutPlanStore = workoutPlanStore
        self.reminderScheduler = reminderScheduler
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
