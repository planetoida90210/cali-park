import Foundation

// MARK: - WorkoutPlanStoring
/// Abstraction over workout-plan persistence, mirroring `WorkoutLogStoring`:
/// view models stay testable with the in-memory stub, and the backend can be
/// swapped later (local JSON now → Supabase/Firebase when it lands).
protocol WorkoutPlanStoring {
    /// Returns all saved plans; empty when none exist yet.
    func load() -> [WorkoutPlan]

    /// Inserts the plan, or replaces the existing one with the same `id`.
    func save(_ plan: WorkoutPlan) throws

    /// Removes the plan with the given identifier; no-op if absent.
    func delete(id: UUID) throws
}

// MARK: - FileWorkoutPlanStore
/// Default `WorkoutPlanStoring` implementation: a single JSON file in the
/// app's documents directory. Adequate for a handful of personal plans;
/// deliberately not Core Data.
struct FileWorkoutPlanStore: WorkoutPlanStoring {
    private let fileURL: URL

    init(directory: URL = .documentsDirectory, fileName: String = "workout-plans.json") {
        fileURL = directory.appending(path: fileName)
    }

    func load() -> [WorkoutPlan] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? Self.decoder.decode([WorkoutPlan].self, from: data)) ?? []
    }

    /// Upsert by `id`: replaces the matching plan in place (keeping order) or
    /// appends a new one, then writes the whole file atomically.
    func save(_ plan: WorkoutPlan) throws {
        var plans = load()
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
        try writeAll(plans)
    }

    func delete(id: UUID) throws {
        var plans = load()
        plans.removeAll { $0.id == id }
        try writeAll(plans)
    }

    private func writeAll(_ plans: [WorkoutPlan]) throws {
        let data = try Self.encoder.encode(plans)
        try data.write(to: fileURL, options: .atomic)
    }

    // ISO 8601 dates keep the JSON file human-readable and stable across formats.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - InMemoryWorkoutPlanStore
/// Non-persistent store for previews and unit tests.
final class InMemoryWorkoutPlanStore: WorkoutPlanStoring {
    private var plans: [WorkoutPlan]

    init(initial: [WorkoutPlan] = []) {
        plans = initial
    }

    func load() -> [WorkoutPlan] { plans }

    func save(_ plan: WorkoutPlan) throws {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
    }

    func delete(id: UUID) throws {
        plans.removeAll { $0.id == id }
    }
}
