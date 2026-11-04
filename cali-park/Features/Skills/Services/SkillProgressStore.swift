import Foundation

// MARK: - SkillProgressStoring
/// Abstraction over `SkillProgress` persistence — the "already celebrated"
/// bookkeeping that keeps the reward loop (SK6) idempotent. Mirrors the other
/// stores so it stays testable and swappable.
///
/// Like placement, this is not secret data: no tokens or entitlement flags, just
/// which celebrations have played. A plain JSON file is the right store.
nonisolated protocol SkillProgressStoring {
    /// The saved progress record, or `nil` when nothing has been celebrated yet.
    /// Throws when a saved record exists but cannot be read.
    func load() throws -> SkillProgress?

    /// Persists the progress record.
    func save(_ progress: SkillProgress) throws

    /// Replaces the saved value; `nil` deletes it, as if nothing had ever
    /// been saved (importing a backup).
    func replace(with progress: SkillProgress?) throws
}

// MARK: - Default replace
nonisolated extension SkillProgressStoring {
    /// Fallback replace: saves a value, and refuses to delete one, since this
    /// store has no way to. Conformers that can delete should override this.
    func replace(with progress: SkillProgress?) throws {
        if let progress {
            try save(progress)
        } else if try load() != nil {
            throw StoreReplaceError.cannotDelete
        }
    }
}

// MARK: - FileSkillProgressStore
/// Default `SkillProgressStoring` implementation: a single JSON file in the
/// app's store directory, through `JSONFileStore`.
nonisolated struct FileSkillProgressStore: SkillProgressStoring {
    private let file: JSONFileStore<SkillProgress>

    init(directory: URL, fileName: String = StoreFile.skillProgress.fileName) {
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

    func replace(with progress: SkillProgress?) throws {
        if let progress { try file.write(progress) } else { try file.remove() }
    }
}
