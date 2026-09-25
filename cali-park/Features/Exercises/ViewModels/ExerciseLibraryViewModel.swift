import Foundation
import Observation

// MARK: - ExerciseLibraryViewModel
/// Drives the exercise library tab: exposes the built-in catalog filtered
/// by the selected category chip and the search text.
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

    // MARK: Init
    init(exercises: [Exercise] = ExerciseCatalog.all) {
        self.exercises = exercises
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
        return exercises.first { $0.id == parentID }
    }

    /// Whether picking `exercise` should first ask which variant was done.
    func hasVariants(_ exercise: Exercise) -> Bool {
        exercise.variantOf == nil && exercises.contains { $0.variantOf == exercise.id }
    }

    /// The choices offered after tapping a movement: the base movement first,
    /// then its variants in catalog order (roughly easiest to hardest).
    func variantChoices(for movement: Exercise) -> [Exercise] {
        [movement] + exercises.filter { $0.variantOf == movement.id }
    }

    // MARK: Filtering
    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func filtered(_ source: [Exercise]) -> [Exercise] {
        var list = source

        if let selectedCategory {
            list = list.filter { $0.category == selectedCategory }
        }

        if !query.isEmpty {
            list = list.filter { $0.name.localizedStandardContains(query) }
        }

        return list
    }
}
