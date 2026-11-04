import Foundation
import Testing
@testable import cali_park

// MARK: - Helpers

private enum FavoritesTestSupport {
    static func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ParkFavoritesTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func quarantineCopies(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("favorite-parks.corrupt-") }
    }

    /// A Park that is not in `ParkFixtures.all`: it left the snapshot.
    static let goneParkID = UUID(uuidString: "D0000000-0000-4000-8000-0000000000EE")!
}

// MARK: - FileFavoriteParkStore

@Suite("Favorite Parks file store")
struct FileFavoriteParkStoreTests {
    @Test("A missing file reads as no favorites")
    func missingFile() throws {
        let directory = try FavoritesTestSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try FileFavoriteParkStore(directory: directory).load().isEmpty)
    }

    @Test("Favorites roundtrip in order through the versioned envelope")
    func roundtrip() throws {
        let directory = try FavoritesTestSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let ids = [ParkFixtures.krakowID, ParkFixtures.mokotowID, FavoritesTestSupport.goneParkID]

        try FileFavoriteParkStore(directory: directory).replaceAll(with: ids)

        #expect(try FileFavoriteParkStore(directory: directory).load() == ids)
        let url = directory.appending(path: "favorite-parks.json")
        let object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        #expect(object["schemaVersion"] as? Int == 1)
        #expect(object["payload"] as? [String] == ids.map(\.uuidString))
    }

    @Test("A corrupt file throws, is copied aside and is never overwritten")
    func corruptFile() throws {
        let directory = try FavoritesTestSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "favorite-parks.json")
        let garbage = Data(#"{"schemaVersion": 1, "payload": ["not-a-uuid"#.utf8)
        try garbage.write(to: url)
        let store = FileFavoriteParkStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.replaceAll(with: [ParkFixtures.mokotowID]) }

        #expect(try Data(contentsOf: url) == garbage)
        let copies = try FavoritesTestSupport.quarantineCopies(in: directory)
        #expect(copies.count == 1)
        #expect(try copies.first.map { try Data(contentsOf: $0) } == garbage)
    }

    @Test("A broken file reaches the Parks tab as an error, not as no favorites")
    @MainActor
    func corruptFileThroughTheService() throws {
        let directory = try FavoritesTestSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("[1, 2".utf8).write(to: directory.appending(path: "favorite-parks.json"))

        let favorites = ParkFavorites(store: FileFavoriteParkStore(directory: directory))

        #expect(favorites.loadFailure != nil)
        #expect(favorites.ids.isEmpty)
        #expect(throws: StoreLoadFailure.self) { try favorites.toggle(ParkFixtures.mokotowID) }
        #expect(throws: StoreLoadFailure.self) { try favorites.currentIDs() }
    }
}

// MARK: - ParkFavorites

@MainActor
@Suite("Favorite Parks service")
struct ParkFavoritesTests {
    @Test("Toggling adds at the end and removes, saving each change")
    func toggle() throws {
        let store = InMemoryFavoriteParkStore(initial: [ParkFixtures.krakowID])
        let favorites = ParkFavorites(store: store)

        try favorites.toggle(ParkFixtures.mokotowID)
        #expect(favorites.ids == [ParkFixtures.krakowID, ParkFixtures.mokotowID])
        #expect(favorites.contains(ParkFixtures.mokotowID))

        try favorites.toggle(ParkFixtures.krakowID)
        #expect(favorites.ids == [ParkFixtures.mokotowID])
        #expect(try store.load() == [ParkFixtures.mokotowID])
        #expect(store.saveCount == 2)
    }

    @Test("A failed save changes nothing")
    func failedSave() throws {
        let store = InMemoryFavoriteParkStore(initial: [ParkFixtures.krakowID])
        let favorites = ParkFavorites(store: store)
        store.failure = .init()

        #expect(throws: (any Error).self) { try favorites.toggle(ParkFixtures.mokotowID) }
        #expect(favorites.ids == [ParkFixtures.krakowID])
    }

    @Test("A store that becomes readable again is picked up on the next change")
    func recoversAfterLoadFailure() throws {
        let store = InMemoryFavoriteParkStore(initial: [ParkFixtures.krakowID], failure: .init())
        let favorites = ParkFavorites(store: store)
        #expect(favorites.loadFailure != nil)

        store.failure = nil
        try favorites.toggle(ParkFixtures.mokotowID)

        #expect(favorites.loadFailure == nil)
        #expect(favorites.ids == [ParkFixtures.krakowID, ParkFixtures.mokotowID])
    }
}

// MARK: - ParkMapViewModel favorites

@MainActor
@Suite("Favorites on the Parks tab")
struct ParkMapFavoritesTests {
    private func makeViewModel(
        favorites initial: [UUID] = [],
        store: InMemoryFavoriteParkStore? = nil,
        authorization: LocationAuthorization = .authorized
    ) async -> (ParkMapViewModel, ParkFavorites) {
        let favorites = ParkFavorites(store: store ?? InMemoryFavoriteParkStore(initial: initial))
        let location = FixedLocationProvider(authorization: authorization, location: ParkFixtures.warsawCentre)
        let viewModel = ParkMapViewModel(directory: InMemoryParkDirectory(parks: ParkFixtures.all),
                                         location: location, favorites: favorites)
        await viewModel.start()
        return (viewModel, favorites)
    }

    @Test("The heart toggles a Park in and out of the favorites")
    func toggleFavorite() async {
        let (viewModel, favorites) = await makeViewModel()

        viewModel.toggleFavorite(ParkFixtures.praga)
        #expect(viewModel.isFavorite(ParkFixtures.praga))
        #expect(favorites.ids == [ParkFixtures.pragaID])

        viewModel.toggleFavorite(ParkFixtures.praga)
        #expect(!viewModel.isFavorite(ParkFixtures.praga))
        #expect(viewModel.favoritesMessage == nil)
    }

    @Test("The Ulubione filter lists only favorites, nearest first")
    func favoritesFilter() async {
        let (viewModel, _) = await makeViewModel(favorites: [ParkFixtures.krakowID, ParkFixtures.mokotowID])

        #expect(viewModel.listItems.count == ParkFixtures.all.count)
        viewModel.listFilter = .favorites
        #expect(viewModel.listItems.map(\.park.id) == [ParkFixtures.mokotowID, ParkFixtures.krakowID])

        viewModel.searchText = "krakow"
        #expect(viewModel.listItems.map(\.park.id) == [ParkFixtures.krakowID])
        // Map search suggestions ignore the list filter.
        viewModel.searchText = "warszawa"
        #expect(viewModel.listItems.map(\.park.id) == [ParkFixtures.mokotowID])
        #expect(viewModel.searchSuggestions.count == 2)
    }

    @Test("A favorite whose Park left the snapshot is kept but not shown")
    func goneParkIsKeptSilently() async {
        let gone = FavoritesTestSupport.goneParkID
        let (viewModel, favorites) = await makeViewModel(favorites: [gone, ParkFixtures.lodzID])
        viewModel.listFilter = .favorites

        #expect(viewModel.listItems.map(\.park.id) == [ParkFixtures.lodzID])
        #expect(viewModel.favoriteCount == 1)

        viewModel.toggleFavorite(ParkFixtures.lodz)
        #expect(viewModel.listItems.isEmpty)
        #expect(favorites.ids == [gone])
    }

    @Test("Unreadable favorites show an error and are never overwritten")
    func unreadableFavorites() async throws {
        let store = InMemoryFavoriteParkStore(initial: [ParkFixtures.krakowID], failure: .init())
        let (viewModel, _) = await makeViewModel(store: store)

        #expect(viewModel.favoritesUnreadable)
        viewModel.toggleFavorite(ParkFixtures.mokotow)

        #expect(viewModel.favoritesMessage == ParkFavorites.loadFailureMessage)
        #expect(store.saveCount == 0)
        store.failure = nil
        #expect(try store.load() == [ParkFixtures.krakowID])
    }

    @Test("A failed save shows its own message")
    func failedSaveMessage() async {
        let store = InMemoryFavoriteParkStore()
        let (viewModel, _) = await makeViewModel(store: store)
        store.failure = .init()

        viewModel.toggleFavorite(ParkFixtures.mokotow)

        #expect(viewModel.favoritesMessage == ParkFavorites.saveFailureMessage)
        #expect(!viewModel.isFavorite(ParkFixtures.mokotow))
    }
}
