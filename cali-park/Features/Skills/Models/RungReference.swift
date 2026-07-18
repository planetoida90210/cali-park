import Foundation

// MARK: - RungReference
/// A stable pointer to one rung of one path: a path identifier plus the rung's
/// index. Used to record which rung advancements have already been celebrated
/// (see `SkillProgress`), so a celebration plays exactly once.
struct RungReference: Codable, Equatable, Hashable, Sendable {
    let pathID: ProgressionPathID
    let rungIndex: Int

    init(pathID: ProgressionPathID, rungIndex: Int) {
        self.pathID = pathID
        self.rungIndex = rungIndex
    }
}
