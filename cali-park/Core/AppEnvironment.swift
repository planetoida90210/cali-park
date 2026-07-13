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

    // MARK: Init
    init(communityPhotoService: CommunityPhotoServiceProtocol = InMemoryCommunityPhotoService(),
         reviewsService: ReviewsServicing = ReviewsService(),
         calendarService: CalendarService = CalendarService(),
         favoritesStore: FavoritesStoring = UserDefaultsFavoritesStore(),
         workoutLogStore: WorkoutLogStoring = FileWorkoutLogStore()) {
        self.communityPhotoService = communityPhotoService
        self.reviewsService = reviewsService
        self.calendarService = calendarService
        self.favoritesStore = favoritesStore
        self.workoutLogStore = workoutLogStore
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

    // MARK: Preview
    static let preview = AppEnvironment()
}
