import Foundation

// MARK: - InMemorySkillProgressStore
/// Non-persistent store for previews and unit tests.
nonisolated final class InMemorySkillProgressStore: SkillProgressStoring {
    private var progress: SkillProgress?

    init(initial: SkillProgress? = nil) {
        progress = initial
    }

    func load() -> SkillProgress? { progress }

    func save(_ progress: SkillProgress) throws {
        self.progress = progress
    }

    func replace(with progress: SkillProgress?) throws {
        self.progress = progress
    }
}
