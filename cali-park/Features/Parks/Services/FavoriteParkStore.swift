import Foundation

// MARK: - FavoriteParkStoring
/// Persistence for the athlete's favorite Parks ("Ulubione"): Park IDs only,
/// on the phone, no Account. IDs of Parks that left the snapshot stay saved.
nonisolated protocol FavoriteParkStoring {
    /// Favorite Park IDs in the order they were added; empty when nothing was
    /// saved. Throws when a saved list exists but cannot be read; callers must
    /// show an error, never treat it as "no favorites".
    func load() throws -> [UUID]

    /// Replaces the saved list.
    func replaceAll(with ids: [UUID]) throws
}

// MARK: - FileFavoriteParkStore
/// Default `FavoriteParkStoring`: one JSON file in the app's store directory
/// (`AppEnvironment.live()` passes it), through `JSONFileStore` (versioned envelope, quarantine of
/// unreadable files, writes refused while the file is broken).
nonisolated struct FileFavoriteParkStore: FavoriteParkStoring {
    private let file: JSONFileStore<[UUID]>

    init(directory: URL, fileName: String = StoreFile.favoriteParks.fileName) {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "FavoriteParkStore")
    }

    func load() throws -> [UUID] {
        try file.read() ?? []
    }

    func replaceAll(with ids: [UUID]) throws {
        try file.write(ids)
    }
}
