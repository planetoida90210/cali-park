@testable import cali_park

// MARK: - Case probes
/// Which case a hero state is, for tests that don't care about its payload.
extension HomeHeroState {
    var isPlanToday: Bool { if case .planToday = self { true } else { false } }
    var isCompletedToday: Bool { if case .completedToday = self { true } else { false } }
    var isRestDay: Bool { if case .restDay = self { true } else { false } }
    var isFreeMode: Bool { if case .freeMode = self { true } else { false } }
}
