import Foundation

// MARK: - SkillPlacement
/// The athlete's self-declared starting point across the progression paths,
/// captured once at onboarding (SK4) and re-adjustable later via calibration.
///
/// A declaration sets the *current* rung of a path — everything below it is
/// treated as conquered without needing logs, so someone who already does 12
/// pull-ups starts from the archer rung rather than from the dead hang. A
/// declaration never grants XP or badges (those come only from real logs), and
/// it never lowers a rung already earned from logs: `ProgressionEngine` takes
/// the max of declaration and logs. Placement is training data, not a secret,
/// so it lives in a plain JSON file (see `PlacementStoring`).
struct SkillPlacement: Codable, Equatable, Sendable {
    /// The declared current rung per path, as a 0-based index into the path's
    /// `steps`. A path absent from the map has no declaration — its state then
    /// comes from logs alone. Missing paths and rung 0 are equivalent (start at
    /// the bottom).
    var declaredRungByPath: [ProgressionPathID: Int]
    /// Equipment the athlete owns, matching `Park.equipments` strings (e.g.
    /// "Resistance bands"). Enables optional parallel-track rungs like band
    /// pull-ups; never required to advance.
    var ownedEquipment: Set<String>
    /// When the placement was declared. Kept for auditing and re-calibration;
    /// it deliberately does not influence XP.
    var declaredAt: Date

    init(declaredRungByPath: [ProgressionPathID: Int] = [:],
         ownedEquipment: Set<String> = [],
         declaredAt: Date = .now) {
        self.declaredRungByPath = declaredRungByPath
        self.ownedEquipment = ownedEquipment
        self.declaredAt = declaredAt
    }

    /// The declared current rung for a path, or `nil` when the athlete made no
    /// declaration for it.
    func declaredRung(for path: ProgressionPathID) -> Int? {
        declaredRungByPath[path]
    }

    /// Whether the athlete declared owning a piece of equipment.
    func ownsEquipment(_ equipment: String) -> Bool {
        ownedEquipment.contains(equipment)
    }

    /// An empty placement: no declarations, no equipment. Handy for previews and
    /// for scoring logs in isolation (badges, XP) where declarations must not
    /// count.
    static let empty = SkillPlacement(
        declaredRungByPath: [:],
        ownedEquipment: [],
        declaredAt: Date(timeIntervalSince1970: 0)
    )
}
