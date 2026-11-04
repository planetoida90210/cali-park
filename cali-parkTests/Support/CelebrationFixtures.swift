@testable import cali_park

// MARK: - Celebration fixtures
extension CelebrationEvent {
    /// The rung at `index` on `path`, conquered. Index 0 is the ladder's first rung.
    static func rung(_ index: Int, on path: ProgressionPathID) -> CelebrationEvent? {
        guard let step = ProgressionCatalog.path(withID: path)?.steps[index] else { return nil }
        return .rungConquered(RungReference(pathID: path, stepID: step.exerciseID))
    }
}
