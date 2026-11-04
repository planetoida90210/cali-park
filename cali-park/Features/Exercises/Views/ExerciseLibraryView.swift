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
                    NavigationLink(value: WorkoutPlansDestination()) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Plany treningowe")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: WorkoutHistoryDestination()) {
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
            .navigationDestination(for: WorkoutHistoryDestination.self) { _ in
                WorkoutHistoryView(viewModel: environment.makeWorkoutHistoryViewModel())
            }
            .navigationDestination(for: WorkoutPlansDestination.self) { _ in
                WorkoutPlansView(environment: environment)
            }
            .sheet(isPresented: $showingQuickWorkout) {
                QuickWorkoutView(viewModel: environment.makeQuickWorkoutViewModel())
            }
        }
    }
}

// MARK: - QuickWorkoutButton
/// Primary "log a whole workout" action, pinned above the tab bar.
private struct QuickWorkoutButton: View {
    let action: () -> Void

    var body: some View {
        Button("Szybki trening", systemImage: "bolt.fill", action: action)
            .buttonStyle(.accent)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - WorkoutHistoryDestination
/// Value-based navigation token for the workout history screen
/// (keeps `navigationDestination(for:)` instead of an inline-destination link).
private struct WorkoutHistoryDestination: Hashable {}

// MARK: - WorkoutPlansDestination
/// Value-based navigation token for the workout plans list.
private struct WorkoutPlansDestination: Hashable {}

// MARK: - ExerciseSearchField
private struct ExerciseSearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.accent)

            TextField("Szukaj ćwiczenia", text: $text)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .submitLabel(.search)
                .foregroundStyle(Color.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                }
                .accessibilityLabel("Wyczyść wyszukiwanie")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .stroke(Color.accent.opacity(isFocused.wrappedValue ? 1 : 0.4), lineWidth: 1)
        )
    }
}

// MARK: - ExerciseLibraryList
private struct ExerciseLibraryList: View {
    let sections: [ExerciseListSection]
    let favorites: ExerciseFavorites

    var body: some View {
        if sections.isEmpty {
            ExerciseEmptyState()
                .padding(.top, 48)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(sections) { section in
                    if let title = section.title {
                        ExerciseListSectionHeader(title: title)
                    }
                    ForEach(section.exercises) { exercise in
                        NavigationLink(value: exercise) {
                            ExerciseRowView(exercise: exercise, isFavorite: favorites.contains(exercise.id))
                        }
                        .exerciseFavoriteActions(exercise)
                    }
                }
            }
        }
    }
}

// MARK: - ExerciseRowView
private struct ExerciseRowView: View {
    let exercise: Exercise
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    if isFavorite {
                        ExerciseFavoriteBadge()
                    }
                }

                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .contentShape(.rect(cornerRadius: AppRadius.medium))
    }

    /// Muscle groups; a favorite variant names its main movement instead.
    private var subtitle: String {
        if let parentID = exercise.variantOf, let parent = ExerciseCatalog.exercise(withID: parentID) {
            return String(localized: "Wariant: \(parent.name)")
        }
        return exercise.muscleGroups.map(\.displayName).joined(separator: " · ")
    }
}

// MARK: - ExerciseEmptyState
private struct ExerciseEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.appTitle2)
                .foregroundStyle(Color.accent.opacity(0.8))

            Text("Brak wyników")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zmień kategorię lub wpisz inną nazwę.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

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
