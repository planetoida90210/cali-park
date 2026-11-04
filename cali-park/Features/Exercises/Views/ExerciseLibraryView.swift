import SwiftUI

// MARK: - ExerciseLibraryView
/// Exercises tab: searchable, filterable list of the built-in calisthenics
/// catalog, favorites ("Ulubione") first. Rows navigate to
/// `ExerciseDetailView` via `navigationDestination`; long-press adds a row to
/// the favorites or removes it.
struct ExerciseLibraryView: View {
    @State private var viewModel: ExerciseLibraryViewModel
    @State private var showingQuickWorkout = false
    @FocusState private var searchFocused: Bool

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: environment.makeExerciseLibraryViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ExerciseSearchField(text: $viewModel.searchText, isFocused: $searchFocused)
                    ExerciseCategoryChips(selection: $viewModel.selectedCategory)
                    ExerciseFavoritesHint(isSearching: viewModel.isSearching)
                    ExerciseLibraryList(
                        sections: viewModel.librarySections(favoriteIDs: environment.exerciseFavorites.ids),
                        favorites: environment.exerciseFavorites
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Ćwiczenia")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                QuickWorkoutButton { showingQuickWorkout = true }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: ExerciseLibraryRoute.workoutPlans) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Plany treningowe")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: ExerciseLibraryRoute.workoutHistory) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Historia treningów")
                }
            }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise, environment: environment)
            }
            .navigationDestination(for: ProgressionPathID.self) { pathID in
                PathDetailView(environment: environment, pathID: pathID)
            }
            .navigationDestination(for: ExerciseLibraryRoute.self) { route in
                switch route {
                case .workoutHistory:
                    WorkoutHistoryView(viewModel: environment.makeWorkoutHistoryViewModel())
                case .workoutPlans:
                    WorkoutPlansView(environment: environment)
                }
            }
            .sheet(isPresented: $showingQuickWorkout) {
                QuickWorkoutView(viewModel: environment.makeQuickWorkoutViewModel())
            }
        }
    }
}

// MARK: - ExerciseLibraryRoute
/// Value-based navigation tokens for the toolbar's screens (keeps
/// `navigationDestination(for:)` instead of an inline-destination link).
private enum ExerciseLibraryRoute: Hashable {
    case workoutHistory
    case workoutPlans
}

#if DEBUG
// MARK: - Preview
#Preview {
    let environment = AppEnvironment.seeded(favoriteExercises: [ExerciseCatalog.australianPullUpsID, ExerciseCatalog.dipsID])
    ExerciseLibraryView(environment: environment)
        .environment(environment.exerciseFavorites)
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    let environment = AppEnvironment.seeded(favoriteExercises: [ExerciseCatalog.australianPullUpsID, ExerciseCatalog.dipsID])
    ExerciseLibraryView(environment: environment)
        .environment(environment.exerciseFavorites)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}
#endif
