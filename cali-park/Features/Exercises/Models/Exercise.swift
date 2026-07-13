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

    init(id: UUID,
         name: String,
         category: ExerciseCategory,
         muscleGroups: [MuscleGroup],
         description: String,
         instructions: [String],
         symbolName: String,
         equipment: [String] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.description = description
        self.instructions = instructions
        self.symbolName = symbolName
        self.equipment = equipment
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}
