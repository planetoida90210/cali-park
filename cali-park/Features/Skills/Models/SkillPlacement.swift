import Foundation

// MARK: - SkillPlacement
/// The athlete's self-declared starting point across the progression paths,
/// captured once at onboarding (SK4) and re-adjustable later via calibration.
///
/// A declaration sets the *current* rung of a path — everything below it is
/// treated as conquered without needing logs, so someone who already does 12
/// pull-ups starts from the L-pull-up rung rather than from the dead hang. A
/// declaration never grants XP or badges (those come only from real logs), and
/// it never lowers a rung already earned from logs: `ProgressionEngine` takes
/// the max of declaration and logs. Placement is training data, not a secret,
/// so it lives in a plain JSON file (see `PlacementStoring`).
struct SkillPlacement: Codable, Equatable, Sendable {
    /// The store schema version this type writes. Version 1 stored rung
    /// indices; version 2 stores the declared rung's step ID.
    static let schemaVersion = 2

    /// The declared current rung per path, as the rung's step ID (the exercise
    /// trained on it), so inserting or reordering rungs never moves a
    /// declaration. A path absent from the map has no declaration — its state
    /// then comes from logs alone. A missing path and the bottom rung are
    /// equivalent (start at the bottom).
    var declaredStepByPath: [ProgressionPathID: UUID]
    /// Equipment the athlete owns, matching `Park.equipments` strings (e.g.
    /// "Resistance bands"). Enables optional parallel-track rungs like band
    /// pull-ups; never required to advance.
    var ownedEquipment: Set<String>
    /// When the placement was declared. Kept for auditing and re-calibration;
    /// it deliberately does not influence XP.
    var declaredAt: Date

    init(declaredStepByPath: [ProgressionPathID: UUID] = [:],
         ownedEquipment: Set<String> = [],
         declaredAt: Date = .now) {
        self.declaredStepByPath = declaredStepByPath
        self.ownedEquipment = ownedEquipment
        self.declaredAt = declaredAt
    }

    /// A placement declared as rung positions in the current catalog, which is
    /// how calibration answers are expressed. A position the path does not have
    /// is dropped.
    init(declaredRungByPath: [ProgressionPathID: Int],
         ownedEquipment: Set<String> = [],
         declaredAt: Date = .now) {
        var steps: [ProgressionPathID: UUID] = [:]
        for (path, index) in declaredRungByPath {
            if let reference = RungReference(pathID: path, rungIndex: index) {
                steps[path] = reference.stepID
            }
        }
        self.init(declaredStepByPath: steps, ownedEquipment: ownedEquipment, declaredAt: declaredAt)
    }

    /// The declared current rung for a path as a position in the current
    /// catalog, or `nil` when the athlete made no declaration for it or the
    /// declared step is no longer on the ladder.
    func declaredRung(for path: ProgressionPathID) -> Int? {
        declaredReference(for: path)?.rungIndex
    }

    /// The declared rung for a path as a stable reference, or `nil` when the
    /// athlete made no declaration for it.
    func declaredReference(for path: ProgressionPathID) -> RungReference? {
        declaredStepByPath[path].map { RungReference(pathID: path, stepID: $0) }
    }

    /// Whether the athlete declared owning a piece of equipment.
    func ownsEquipment(_ equipment: String) -> Bool {
        ownedEquipment.contains(equipment)
    }

    /// An empty placement: no declarations, no equipment. Handy for previews and
    /// for scoring logs in isolation (badges, XP) where declarations must not
    /// count.
    static let empty = SkillPlacement(
        declaredStepByPath: [:],
        ownedEquipment: [],
        declaredAt: Date(timeIntervalSince1970: 0)
    )

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        /// Version 2: `{"pullUp": "<step UUID>", …}`.
        case declaredStepByPath
        /// Version 1: `["pullUp", 4, …]` (a dictionary with enum keys, which
        /// `JSONEncoder` writes as a flat key/value array).
        case declaredRungByPath
        case ownedEquipment
        case declaredAt
    }

    /// Reads the current format, or migrates version 1 (rung indices) through
    /// the frozen `LadderOrderV1`, so an old declaration keeps pointing at the
    /// exercise it named when it was saved. An index that was never valid is
    /// dropped (that path starts from logs alone).
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ownedEquipment = try container.decode(Set<String>.self, forKey: .ownedEquipment)
        declaredAt = try container.decode(Date.self, forKey: .declaredAt)

        let version = JSONFileFormat.schemaVersion(of: decoder) ?? Self.schemaVersion
        if version < 2 {
            let legacy = try container.decode([ProgressionPathID: Int].self, forKey: .declaredRungByPath)
            var steps: [ProgressionPathID: UUID] = [:]
            for (path, index) in legacy {
                if let stepID = LadderOrderV1.stepID(for: path, rungIndex: index) {
                    steps[path] = stepID
                }
            }
            declaredStepByPath = steps
        } else {
            let stored = try container.decode([String: UUID].self, forKey: .declaredStepByPath)
            var steps: [ProgressionPathID: UUID] = [:]
            for (rawPath, stepID) in stored {
                guard let path = ProgressionPathID(rawValue: rawPath) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .declaredStepByPath, in: container,
                        debugDescription: "Unknown progression path \(rawPath)"
                    )
                }
                steps[path] = stepID
            }
            declaredStepByPath = steps
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let stored = Dictionary(uniqueKeysWithValues: declaredStepByPath.map { ($0.key.rawValue, $0.value) })
        try container.encode(stored, forKey: .declaredStepByPath)
        try container.encode(ownedEquipment, forKey: .ownedEquipment)
        try container.encode(declaredAt, forKey: .declaredAt)
    }
}
