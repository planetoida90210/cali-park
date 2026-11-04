import Foundation
import Testing
@testable import cali_park

// MARK: - Helpers

private enum ExerciseFavoritesSupport {
    static func makeDirectory() throws -> URL {
        let directory = try TemporaryDirectory.make("ExerciseFavoritesTests")
        return directory
    }

    static func quarantineCopies(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("favorite-exercises.corrupt-") }
    }

    /// An exercise that is not in the catalog: it was removed.
    static let goneExerciseID = UUID(uuidString: "E0000000-0000-4000-8000-0000000FFFFF")!

    static func exercise(_ id: Int, _ name: String, _ category: ExerciseCategory = .basic,
                         variantOf parent: Int? = nil) -> Exercise {
        Exercise(
            id: uuid(id),
            name: name,
            category: category,
            muscleGroups: [.back],
            description: "Test",
            instructions: ["a"],
            symbolName: "figure.climbing",
            variantOf: parent.map(uuid)
        )
    }

    static func uuid(_ id: Int) -> UUID {
        let digits = String(id)
        return UUID(uuidString: "F1000000-0000-4000-8000-" + String(repeating: "0", count: 12 - digits.count) + digits)!
    }

    /// A small fixed catalog: two movements with variants, one without.
    static let pullUps = exercise(1, "Podciągnięcia")
    static let australian = exercise(2, "Podciągnięcia australijskie", variantOf: 1)
    static let archer = exercise(3, "Podciągnięcia łucznicze", .advanced, variantOf: 1)
    static let pushUps = exercise(4, "Pompki")
    static let diamond = exercise(5, "Pompki diamentowe", .advanced, variantOf: 4)
    static let muscleUp = exercise(6, "Muscle-up", .expert)
    static let catalog = [pullUps, australian, archer, pushUps, diamond, muscleUp]
    static let mainMovements = [pullUps, pushUps, muscleUp]
}

// MARK: - FileFavoriteExerciseStore

@Suite("Favorite exercises file store", .temporaryDirectories)
struct FileFavoriteExerciseStoreTests {
    @Test("A missing file reads as no favorites")
    func missingFile() throws {
        let directory = try ExerciseFavoritesSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try FileFavoriteExerciseStore(directory: directory).load().isEmpty)
    }

    @Test("Favorites roundtrip in order through the versioned envelope")
    func roundtrip() throws {
        let directory = try ExerciseFavoritesSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let ids = [ExerciseCatalog.australianPullUpsID, ExerciseCatalog.pullUpsID, ExerciseFavoritesSupport.goneExerciseID]

        try FileFavoriteExerciseStore(directory: directory).replaceAll(with: ids)

        #expect(try FileFavoriteExerciseStore(directory: directory).load() == ids)
        let url = directory.appending(path: "favorite-exercises.json")
        let object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        #expect(object["schemaVersion"] as? Int == 1)
        #expect(object["payload"] as? [String] == ids.map(\.uuidString))
    }

    @Test("A corrupt file throws, is copied aside and is never overwritten")
    func corruptFile() throws {
        let directory = try ExerciseFavoritesSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "favorite-exercises.json")
        let garbage = Data(#"{"schemaVersion": 1, "payload": ["not-a-uuid"#.utf8)
        try garbage.write(to: url)
        let store = FileFavoriteExerciseStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.replaceAll(with: [ExerciseCatalog.dipsID]) }

        #expect(try Data(contentsOf: url) == garbage)
        let copies = try ExerciseFavoritesSupport.quarantineCopies(in: directory)
        #expect(copies.count == 1)
        #expect(try copies.first.map { try Data(contentsOf: $0) } == garbage)
    }

    @Test("A broken file reaches the screens as an error, not as no favorites")
    @MainActor
    func corruptFileThroughTheService() throws {
        let directory = try ExerciseFavoritesSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("[1, 2".utf8).write(to: directory.appending(path: "favorite-exercises.json"))

        let favorites = ExerciseFavorites(store: FileFavoriteExerciseStore(directory: directory))

        #expect(favorites.loadFailure != nil)
        #expect(favorites.ids.isEmpty)
        #expect(throws: StoreLoadFailure.self) { try favorites.toggle(ExerciseCatalog.dipsID) }
        #expect(throws: StoreLoadFailure.self) { try favorites.currentIDs() }
        #expect(favorites.toggleReportingFailure(ExerciseCatalog.dipsID) == ExerciseFavorites.loadFailureMessage)
    }
}

// MARK: - ExerciseFavorites

@MainActor
@Suite("Favorite exercises service")
struct ExerciseFavoritesTests {
    @Test("Toggling adds at the end and removes, saving each change")
    func toggle() throws {
        let store = InMemoryFavoriteExerciseStore(initial: [ExerciseCatalog.pullUpsID])
        let favorites = ExerciseFavorites(store: store)

        try favorites.toggle(ExerciseCatalog.australianPullUpsID)
        #expect(favorites.ids == [ExerciseCatalog.pullUpsID, ExerciseCatalog.australianPullUpsID])
        #expect(favorites.contains(ExerciseCatalog.australianPullUpsID))

        try favorites.toggle(ExerciseCatalog.pullUpsID)
        #expect(favorites.ids == [ExerciseCatalog.australianPullUpsID])
        #expect(try store.load() == [ExerciseCatalog.australianPullUpsID])
        #expect(store.saveCount == 2)
    }

    @Test("A failed save changes nothing and reports the save message")
    func failedSave() throws {
        let store = InMemoryFavoriteExerciseStore(initial: [ExerciseCatalog.pullUpsID])
        let favorites = ExerciseFavorites(store: store)
        store.failure = .init()

        #expect(favorites.toggleReportingFailure(ExerciseCatalog.dipsID) == ExerciseFavorites.saveFailureMessage)
        #expect(favorites.ids == [ExerciseCatalog.pullUpsID])
        #expect(store.saveCount == 0)
    }

    @Test("Unreadable favorites are never overwritten by a toggle")
    func unreadableNeverOverwritten() throws {
        let store = InMemoryFavoriteExerciseStore(initial: [ExerciseCatalog.pullUpsID], failure: .init())
        let favorites = ExerciseFavorites(store: store)

        #expect(favorites.toggleReportingFailure(ExerciseCatalog.dipsID) == ExerciseFavorites.loadFailureMessage)
        #expect(store.saveCount == 0)
        store.failure = nil
        #expect(try store.load() == [ExerciseCatalog.pullUpsID])
    }

    @Test("A store that becomes readable again is picked up on the next change")
    func recoversAfterLoadFailure() throws {
        let store = InMemoryFavoriteExerciseStore(initial: [ExerciseCatalog.pullUpsID], failure: .init())
        let favorites = ExerciseFavorites(store: store)
        #expect(favorites.loadFailure != nil)

        store.failure = nil
        #expect(favorites.toggleReportingFailure(ExerciseCatalog.dipsID) == nil)

        #expect(favorites.loadFailure == nil)
        #expect(favorites.ids == [ExerciseCatalog.pullUpsID, ExerciseCatalog.dipsID])
    }

    @Test("The app environment shares one favorites list, seeded for previews")
    func environmentWiring() throws {
        let environment = AppEnvironment.seeded(favoriteExercises: [ExerciseCatalog.dipsID])
        #expect(environment.exerciseFavorites.ids == [ExerciseCatalog.dipsID])
        try environment.exerciseFavorites.toggle(ExerciseCatalog.plankID)
        let backup = try environment.makeTrainingBackupService().currentBackup()
        #expect(backup.favoriteExerciseIDs == [ExerciseCatalog.dipsID, ExerciseCatalog.plankID])
    }
}

// MARK: - ExerciseListSections

@Suite("Exercise list sections: favorites first")
struct ExerciseListSectionsTests {
    fileprivate typealias S = ExerciseFavoritesSupport

    private func sections(favorites: [UUID] = [],
                          category: ExerciseCategory? = nil,
                          query: String = "",
                          includesVariants: Bool = true) -> [ExerciseListSection] {
        ExerciseListSections.make(catalog: S.catalog, favoriteIDs: favorites,
                                  category: category, query: query, includesVariants: includesVariants)
    }

    @Test("Without favorites the list is the catalog as before, untitled")
    func noFavorites() {
        let result = sections()
        #expect(result == [ExerciseListSection(kind: .catalog, title: nil, exercises: S.mainMovements)])
    }

    @Test("Favorites come first in the order they were added, then the whole catalog")
    func favoritesFirst() {
        let result = sections(favorites: [S.muscleUp.id, S.australian.id, S.pullUps.id])

        #expect(result.map(\.kind) == [.favorites, .catalog])
        #expect(result.map(\.title) == ["Ulubione", "Wszystkie ćwiczenia"])
        // Variants can be favorites; the order is the order of adding.
        #expect(result[0].exercises == [S.muscleUp, S.australian, S.pullUps])
        // The catalog list keeps every movement in its usual place.
        #expect(result[1].exercises == S.mainMovements)
    }

    @Test("Favorites of exercises removed from the catalog are skipped")
    func unknownIDsIgnored() {
        let result = sections(favorites: [S.goneExerciseID, S.pushUps.id])
        #expect(result[0].exercises == [S.pushUps])

        let onlyGone = sections(favorites: [S.goneExerciseID])
        #expect(onlyGone == [ExerciseListSection(kind: .catalog, title: nil, exercises: S.mainMovements)])
    }

    @Test("A repeated ID shows once")
    func duplicateIDs() {
        #expect(sections(favorites: [S.pushUps.id, S.pushUps.id])[0].exercises == [S.pushUps])
    }

    @Test("The category chip filters the favorites too")
    func categoryFiltersFavorites() {
        let result = sections(favorites: [S.archer.id, S.pullUps.id], category: .advanced)
        #expect(result.map(\.kind) == [.favorites])
        #expect(result[0].exercises == [S.archer])

        let basic = sections(favorites: [S.archer.id], category: .basic)
        #expect(basic == [ExerciseListSection(kind: .catalog, title: nil, exercises: [S.pullUps, S.pushUps])])
    }

    @Test("Search searches everything, variants included, as one untitled list", arguments: [
        ("pompki", ["Pompki", "Pompki diamentowe"]),
        ("podciagniecia", ["Podciągnięcia", "Podciągnięcia australijskie", "Podciągnięcia łucznicze"]),
        ("  łucznicze ", ["Podciągnięcia łucznicze"])
    ])
    func searchSearchesEverything(query: String, names: [String]) throws {
        let result = sections(favorites: [S.muscleUp.id], query: query)
        try #require(result.count == 1)
        #expect(result[0].kind == .catalog)
        #expect(result[0].title == nil)
        #expect(result[0].exercises.map(\.name) == names)
    }

    @Test("The Exercises tab's search matches main movements only")
    func librarySearchMainOnly() {
        let result = sections(query: "pompki", includesVariants: false)
        #expect(result.flatMap(\.exercises) == [S.pushUps])
    }

    @Test("No match leaves no sections")
    func noMatch() {
        #expect(sections(favorites: [S.pushUps.id], query: "kettlebell").isEmpty)
    }

    @Test("The library and picker view models feed their filters into the sections")
    @MainActor
    func viewModelSections() {
        let viewModel = ExerciseLibraryViewModel(exercises: S.catalog)
        viewModel.selectedCategory = .advanced
        #expect(viewModel.pickerSections(favoriteIDs: [S.diamond.id]).flatMap(\.exercises) == [S.diamond])
        #expect(!viewModel.isSearching)

        viewModel.selectedCategory = nil
        viewModel.searchText = "diament"
        #expect(viewModel.isSearching)
        #expect(viewModel.pickerSections(favoriteIDs: []).flatMap(\.exercises) == [S.diamond])
        #expect(viewModel.librarySections(favoriteIDs: []).isEmpty)
    }

    @Test("Real catalog: a favorite pull-up variant is one tap from the top")
    func realCatalog() throws {
        let result = ExerciseListSections.make(catalog: ExerciseCatalog.all,
                                               favoriteIDs: [ExerciseCatalog.australianPullUpsID],
                                               category: nil, query: "", includesVariants: true)
        let australian = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.australianPullUpsID))
        #expect(result.first?.exercises == [australian])
        #expect(result.last?.exercises == ExerciseCatalog.mainMovements)
    }
}

// MARK: - Ostatnio

@Suite("Exercise picker: recently used")
struct ExerciseRecentSectionTests {
    fileprivate typealias S = ExerciseFavoritesSupport

    private func sections(favorites: [UUID] = [],
                          recent: [UUID],
                          category: ExerciseCategory? = nil,
                          query: String = "") -> [ExerciseListSection] {
        ExerciseListSections.make(catalog: S.catalog, favoriteIDs: favorites, recentExerciseIDs: recent,
                                  category: category, query: query, includesVariants: true)
    }

    @Test("Ostatnio comes after Ulubione, newest first, each exercise once")
    func order() {
        let result = sections(favorites: [S.pullUps.id],
                              recent: [S.diamond.id, S.archer.id, S.diamond.id, S.muscleUp.id])

        #expect(result.map(\.kind) == [.favorites, .recent, .catalog])
        #expect(result.map(\.title) == ["Ulubione", "Ostatnio", "Wszystkie ćwiczenia"])
        #expect(result[1].exercises == [S.diamond, S.archer, S.muscleUp])
    }

    @Test("Favorites never repeat in Ostatnio")
    func excludesFavorites() {
        let result = sections(favorites: [S.archer.id], recent: [S.archer.id, S.pushUps.id, S.archer.id])
        #expect(result[1].kind == .recent)
        #expect(result[1].exercises == [S.pushUps])
    }

    @Test("Without favorites, Ostatnio leads and the catalog gets its title")
    func recentWithoutFavorites() {
        let result = sections(recent: [S.pushUps.id])
        #expect(result.map(\.kind) == [.recent, .catalog])
        #expect(result.last?.title == "Wszystkie ćwiczenia")
    }

    @Test("At most five, counted after favorites and removed exercises are skipped")
    func limit() {
        let many = [S.goneExerciseID, S.pullUps.id] + S.catalog.map(\.id)
        let result = sections(favorites: [S.pullUps.id], recent: many)

        #expect(result[1].exercises == [S.australian, S.archer, S.pushUps, S.diamond, S.muscleUp])
        #expect(ExerciseListSections.recentLimit == 5)
    }

    @Test("Reading stops once Ostatnio is full")
    func stopsEarly() {
        var read = 0
        let ids = S.catalog.map(\.id) + Array(repeating: S.pullUps.id, count: 1_000)
        let counted = ids.lazy.map { id -> UUID in
            read += 1
            return id
        }
        _ = ExerciseListSections.make(catalog: S.catalog, favoriteIDs: [], recentExerciseIDs: counted,
                                      category: nil, query: "", includesVariants: true)
        #expect(read == 5)
    }

    @Test("The category chip filters Ostatnio too")
    func categoryFilters() {
        let result = sections(recent: [S.archer.id, S.pushUps.id, S.diamond.id], category: .advanced)
        #expect(result.first?.kind == .recent)
        #expect(result.first?.exercises == [S.archer, S.diamond])
    }

    @Test("A search hides Ostatnio and searches everything")
    func searchHidesRecent() {
        let result = sections(recent: [S.muscleUp.id], query: "muscle")
        #expect(result.map(\.kind) == [.catalog])
        #expect(result[0].exercises == [S.muscleUp])
    }

    @Test("The picker reads Ostatnio from the journal, newest entry first")
    @MainActor
    func fromJournal() {
        let reference = Date(timeIntervalSince1970: 1_790_000_000)
        func entry(_ id: UUID, daysAgo: Int) -> WorkoutLogEntry {
            WorkoutLogEntry(exerciseID: id,
                            date: reference.addingTimeInterval(-Double(daysAgo) * 86_400),
                            sets: [LoggedSet(reps: 5)])
        }
        let environment = AppEnvironment.seeded(
            logs: [
                entry(ExerciseCatalog.dipsID, daysAgo: 3),
                entry(ExerciseCatalog.squatsID, daysAgo: 1),
                entry(S.goneExerciseID, daysAgo: 0)
            ],
            favoriteExercises: [ExerciseCatalog.pullUpsID]
        )
        let viewModel = environment.makeExerciseLibraryViewModel()

        let result = viewModel.pickerSections(
            favoriteIDs: environment.exerciseFavorites.ids,
            recentExerciseIDs: environment.journal.newestFirst.lazy.map(\.exerciseID)
        )

        #expect(result.map(\.kind) == [.favorites, .recent, .catalog])
        #expect(result[1].exercises.map(\.id) == [ExerciseCatalog.squatsID, ExerciseCatalog.dipsID])
    }
}
