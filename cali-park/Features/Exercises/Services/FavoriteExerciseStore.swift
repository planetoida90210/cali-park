import Foundation

// MARK: - FavoriteExerciseStoring
/// Persistence for the athlete's favorite exercises ("Ulubione"): catalog
/// exercise IDs only, on the phone, no Account. IDs of exercises that left the
/// catalog stay saved.
nonisolated protocol FavoriteExerciseStoring {
    /// Favorite exercise IDs in the order they were added; empty when nothing
    /// was saved. Throws when a saved list exists but cannot be read; callers
    /// must show an error, never treat it as "no favorites".
    func load() throws -> [UUID]

    /// Replaces the saved list.
    func replaceAll(with ids: [UUID]) throws
}

// MARK: - FileFavoriteExerciseStore
/// Default `FavoriteExerciseStoring`: one JSON file in the app's store
/// directory (`AppEnvironment.live()` passes it), through `JSONFileStore`
/// (versioned envelope, quarantine of unreadable files, writes refused while
/// the file is broken).
nonisolated struct FileFavoriteExerciseStore: FavoriteExerciseStoring {
    private let file: JSONFileStore<[UUID]>

    init(directory: URL, fileName: String = StoreFile.favoriteExercises.fileName) {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "FavoriteExerciseStore")
    }

    func load() throws -> [UUID] {
        try file.read() ?? []
    }

    func replaceAll(with ids: [UUID]) throws {
        try file.write(ids)
    }
}
