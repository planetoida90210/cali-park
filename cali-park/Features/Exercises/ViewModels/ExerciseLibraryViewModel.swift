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
        var list = exercises.filter { $0.variantOf == nil }

        if let selectedCategory {
            list = list.filter { $0.category == selectedCategory }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            list = list.filter { $0.name.localizedStandardContains(query) }
        }

        return list
    }
}
