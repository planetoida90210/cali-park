import Foundation

// MARK: - InMemorySkillPlacementStore
/// Non-persistent store for previews and unit tests.
nonisolated final class InMemorySkillPlacementStore: PlacementStoring {
    private var placement: SkillPlacement?

    init(initial: SkillPlacement? = nil) {
        placement = initial
    }

    func load() -> SkillPlacement? { placement }

    func save(_ placement: SkillPlacement) throws {
        self.placement = placement
    }

    func replace(with placement: SkillPlacement?) throws {
        self.placement = placement
    }
}
