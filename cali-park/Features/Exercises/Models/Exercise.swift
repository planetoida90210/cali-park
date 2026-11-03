import Foundation

// MARK: - Exercise
/// A single calisthenics exercise from the built-in catalog.
/// Identifiers are fixed UUIDs (see `ExerciseCatalog`) so workout log entries
/// keyed by `exerciseID` survive app restarts and catalog updates.
struct Exercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [MuscleGroup]
    var description: String
    var instructions: [String]
    /// SF Symbol from the `figure.*` family, rendered Watch-Workout style
    /// (black glyph on an accent circle).
    var symbolName: String
    /// Park equipment needed, matching strings used in `Park.equipments`.
    var equipment: [String]
    /// Whether a set is counted in reps or in seconds held. Defaults to
    /// `.reps`; isometric holds (planks, levers) use `.seconds`.
    var measurement: ExerciseMeasurement
    /// The main movement this exercise is a progression variant of, e.g. wall
    /// push-ups point at full push-ups. `nil` marks a main movement — only
    /// main movements appear in the exercise library; variants live on the
    /// skill ladders. The parent is always a main movement (a flat, one-level
    /// hierarchy), never another variant.
    var variantOf: UUID?
    /// How a one-sided exercise is counted ("na rękę", "na nogę", "na
    /// stronę"); `nil` for a two-sided movement.
    var unilateralSide: UnilateralSide?

    /// Whether the exercise works one side at a time, so its targets count
    /// per side.
    var isUnilateral: Bool { unilateralSide != nil }

    init(id: UUID,
         name: String,
         category: ExerciseCategory,
         muscleGroups: [MuscleGroup],
         description: String,
         instructions: [String],
         symbolName: String,
         equipment: [String] = [],
         measurement: ExerciseMeasurement = .reps,
         variantOf: UUID? = nil,
         unilateralSide: UnilateralSide? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.description = description
        self.instructions = instructions
        self.symbolName = symbolName
        self.equipment = equipment
        self.measurement = measurement
        self.variantOf = variantOf
        self.unilateralSide = unilateralSide
    }

    // MARK: Codable
    // `measurement`, `variantOf`, `equipment` and `unilateralSide` decode with
    // defaults so catalog snapshots encoded before these fields existed still
    // load.
    private enum CodingKeys: String, CodingKey {
        case id, name, category, muscleGroups, description
        case instructions, symbolName, equipment, measurement, variantOf
        case unilateralSide
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(ExerciseCategory.self, forKey: .category)
        muscleGroups = try container.decode([MuscleGroup].self, forKey: .muscleGroups)
        description = try container.decode(String.self, forKey: .description)
        instructions = try container.decode([String].self, forKey: .instructions)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        equipment = try container.decodeIfPresent([String].self, forKey: .equipment) ?? []
        measurement = try container.decodeIfPresent(ExerciseMeasurement.self, forKey: .measurement) ?? .reps
        variantOf = try container.decodeIfPresent(UUID.self, forKey: .variantOf)
        unilateralSide = try container.decodeIfPresent(UnilateralSide.self, forKey: .unilateralSide)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}
