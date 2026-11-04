import Foundation

// MARK: - ExerciseListSection
/// One block of an exercise list: "Ulubione" first, then the whole catalog.
nonisolated struct ExerciseListSection: Identifiable, Equatable, Sendable {
    enum Kind: Hashable, Sendable {
        /// The athlete's favorite exercises, in the order they were added.
        case favorites
        /// The catalog list as it always was (or the search results).
        case catalog
    }

    let kind: Kind
    /// The header; `nil` when the catalog is the only section, so a list
    /// without favorites looks exactly as before.
    let title: String?
    let exercises: [Exercise]

    var id: Kind { kind }
}

// MARK: - ExerciseListSections
/// Builds the sections of the exercise pickers and the Exercises tab. Pure,
/// so the order is tested without a screen.
///
/// - With a search query there is one untitled section: every match, in
///   catalog order. Search always searches everything.
/// - Without one, "Ulubione" (favorites in the order they were added) comes
///   first, then "Wszystkie ćwiczenia": the catalog list exactly as before,
///   favorites included, so nothing moves out of its usual place.
/// - The category chip filters every section.
/// - Favorite IDs missing from the catalog are skipped.
nonisolated enum ExerciseListSections {
    static let favoritesTitle = "Ulubione"
    static let catalogTitle = "Wszystkie ćwiczenia"

    /// - Parameters:
    ///   - catalog: every exercise, progression variants included.
    ///   - includesVariants: whether search also matches progression variants
    ///     (the pickers) or only main movements (the Exercises tab). The
    ///     catalog section without a search lists main movements only.
    static func make(catalog: [Exercise],
                     favoriteIDs: [UUID],
                     category: ExerciseCategory?,
                     query: String,
                     includesVariants: Bool) -> [ExerciseListSection] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let mainMovements = catalog.filter { $0.variantOf == nil }

        guard query.isEmpty else {
            let matches = filtered(includesVariants ? catalog : mainMovements, category: category, query: query)
            return matches.isEmpty ? [] : [ExerciseListSection(kind: .catalog, title: nil, exercises: matches)]
        }

        let byID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let favorites = filtered(unique(favoriteIDs).compactMap { byID[$0] }, category: category, query: "")
        let everything = filtered(mainMovements, category: category, query: "")

        var sections: [ExerciseListSection] = []
        if !favorites.isEmpty {
            sections.append(ExerciseListSection(kind: .favorites, title: favoritesTitle, exercises: favorites))
        }
        if !everything.isEmpty {
            sections.append(ExerciseListSection(kind: .catalog,
                                                title: sections.isEmpty ? nil : catalogTitle,
                                                exercises: everything))
        }
        return sections
    }

    /// `source` narrowed to `category` (`nil` = every category) and to names
    /// containing `query`, case- and diacritic-insensitively, so
    /// "podciagniecia" finds "Podciągnięcia". Keeps the order of `source`.
    static func filtered(_ source: [Exercise], category: ExerciseCategory?, query: String) -> [Exercise] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return source.filter { exercise in
            (category == nil || exercise.category == category)
                && (query.isEmpty || exercise.name.localizedStandardContains(query))
        }
    }

    private static func unique(_ ids: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }
}
