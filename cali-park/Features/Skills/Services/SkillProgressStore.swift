import Foundation

// MARK: - SkillProgressStoring
/// Abstraction over `SkillProgress` persistence — the "already celebrated"
/// bookkeeping that keeps the reward loop (SK6) idempotent. Mirrors the other
/// stores so it stays testable and swappable.
///
/// Like placement, this is not secret data: no tokens or entitlement flags, just
/// which celebrations have played. A plain JSON file is the right store.
protocol SkillProgressStoring {
    /// The saved progress record, or `nil` when nothing has been celebrated yet.
    /// Throws when a saved record exists but cannot be read.
    func load() throws -> SkillProgress?

    /// Persists the progress record.
    func save(_ progress: SkillProgress) throws
}

// MARK: - FileSkillProgressStore
/// Default `SkillProgressStoring` implementation: a single JSON file in the
/// app's documents directory, through `JSONFileStore`.
struct FileSkillProgressStore: SkillProgressStoring {
    private let file: JSONFileStore<SkillProgress>

    init(directory: URL = .documentsDirectory, fileName: String = "skill-progress.json") {
        file = JSONFileStore(
            fileURL: directory.appending(path: fileName),
            logCategory: "SkillProgressStore",
            schemaVersion: SkillProgress.schemaVersion
        )
    }

    func load() throws -> SkillProgress? {
        try file.read()
    }

    func save(_ progress: SkillProgress) throws {
        try file.write(progress)
    }
}

// MARK: - InMemorySkillProgressStore
/// Non-persistent store for previews and unit tests.
final class InMemorySkillProgressStore: SkillProgressStoring {
    private var progress: SkillProgress?

    init(initial: SkillProgress? = nil) {
        progress = initial
    }

    func load() -> SkillProgress? { progress }

    func save(_ progress: SkillProgress) throws {
        self.progress = progress
    }
}
