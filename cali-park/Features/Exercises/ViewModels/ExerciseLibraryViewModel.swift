import Foundation
import Observation

// MARK: - ExerciseLibraryViewModel
/// Drives the exercise library tab and the exercise pickers: exposes the
/// built-in catalog filtered by the selected category chip and the search
/// text, with the athlete's favorites first (`ExerciseListSections`).
@MainActor
@Observable
final class ExerciseLibraryViewModel {
    // MARK: Filters
    var searchText: String = ""
    /// `nil` means "all categories" (the default chip).
    var selectedCategory: ExerciseCategory?

    // MARK: Dependencies
    /// Catalog snapshot — injected for tests, `ExerciseCatalog.all` in
    /// production. Progression variants are filtered out below, so the library
    /// only ever lists main movements.
    private let exercises: [Exercise]
    /// Lookups the picker rows ask for, built once instead of scanning the
    /// catalog per row (audit E-26).
    private let exercisesByID: [UUID: Exercise]
    private let movementIDsWithVariants: Set<UUID>

    // MARK: Init
    init(exercises: [Exercise] = ExerciseCatalog.all) {
        self.exercises = exercises
        exercisesByID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        movementIDsWithVariants = Set(exercises.compactMap(\.variantOf))
    }

    // MARK: Output
    /// Main movements matching the current category and search filters, in
    /// catalog order (basic → expert). Progression variants (`variantOf != nil`)
    /// never appear here — they live on the skill ladders. Search is case- and
    /// diacritic-insensitive, so "podciagniecia" finds "Podciągnięcia".
    var displayedExercises: [Exercise] {
        filtered(exercises.filter { $0.variantOf == nil })
    }

    /// What the quick-workout picker lists. With an empty search it matches the
    /// library (main movements only); a non-empty query also matches progression
    /// variants, so "diamentowe" finds "Pompki diamentowe". Catalog order, same
    /// category filter.
    var pickerExercises: [Exercise] {
        query.isEmpty ? displayedExercises : filtered(exercises)
    }

    /// The main movement `exercise` is a variant of; `nil` for a main movement.
    func parent(of exercise: Exercise) -> Exercise? {
        guard let parentID = exercise.variantOf else { return nil }
        return exercisesByID[parentID]
    }

    /// Whether picking `exercise` should first ask which variant was done.
    func hasVariants(_ exercise: Exercise) -> Bool {
        exercise.variantOf == nil && movementIDsWithVariants.contains(exercise.id)
    }

    /// The choices offered after tapping a movement: the base movement first,
    /// then its variants in catalog order (roughly easiest to hardest).
    func variantChoices(for movement: Exercise) -> [Exercise] {
        [movement] + exercises.filter { $0.variantOf == movement.id }
    }

    /// The Exercises tab: "Ulubione" first, then every main movement. Search
    /// matches main movements only, like `displayedExercises`.
    func librarySections(favoriteIDs: [UUID]) -> [ExerciseListSection] {
        ExerciseListSections.make(
            catalog: exercises, favoriteIDs: favoriteIDs,
            category: selectedCategory, query: searchText, includesVariants: false)
    }

    /// The exercise pickers: "Ulubione" first, then "Ostatnio" (from
    /// `recentExerciseIDs`, newest first), then every main movement. Search
    /// also matches progression variants, like `pickerExercises`.
    func pickerSections(
        favoriteIDs: [UUID],
        recentExerciseIDs: some Sequence<UUID> = [UUID]()
    ) -> [ExerciseListSection] {
        ExerciseListSections.make(
            catalog: exercises, favoriteIDs: favoriteIDs, recentExerciseIDs: recentExerciseIDs,
            category: selectedCategory, query: searchText, includesVariants: true)
    }

    /// Whether a search query is entered (the lists then show only matches).
    var isSearching: Bool { !query.isEmpty }

    // MARK: Filtering
    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func filtered(_ source: [Exercise]) -> [Exercise] {
        ExerciseListSections.filtered(source, category: selectedCategory, query: query)
    }
}
