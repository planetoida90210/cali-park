import Foundation

// MARK: - WorkoutPlanStoring
/// Abstraction over workout-plan persistence, mirroring `WorkoutLogStoring`:
/// view models stay testable with the in-memory stub, and the backend can be
/// swapped later (local JSON now → Supabase/Firebase when it lands).
protocol WorkoutPlanStoring {
    /// Returns all saved plans; empty when none exist yet. Throws when saved
    /// plans exist but cannot be read.
    func load() throws -> [WorkoutPlan]

    /// Inserts the plan, or replaces the existing one with the same `id`.
    func save(_ plan: WorkoutPlan) throws

    /// Removes the plan with the given identifier; no-op if absent.
    func delete(id: UUID) throws

    /// Replaces every saved plan with `plans` (importing a backup).
    func replaceAll(with plans: [WorkoutPlan]) throws
}

// MARK: - Default replace
extension WorkoutPlanStoring {
    /// Fallback replace: deletes every plan, then saves the new ones. Not
    /// atomic — conformers that can write once should override this.
    func replaceAll(with plans: [WorkoutPlan]) throws {
        for plan in try load() {
            try delete(id: plan.id)
        }
        for plan in plans {
            try save(plan)
        }
    }
}

// MARK: - FileWorkoutPlanStore
/// Default `WorkoutPlanStoring` implementation: a single JSON file in the
/// app's store directory, through `JSONFileStore`. Adequate for a handful
/// of personal plans; deliberately not Core Data.
struct FileWorkoutPlanStore: WorkoutPlanStoring {
    private let file: JSONFileStore<[WorkoutPlan]>

    /// Version 2 stores schedule days as `"yyyy-MM-dd"` (`CalendarDay`).
    /// Version 1 stored instants; they are read as days in `calendar`.
    static let schemaVersion = 2

    /// - Parameter calendar: turns the instants of version 1 files into days.
    init(directory: URL,
         fileName: String = StoreFile.workoutPlans.fileName,
         calendar: Calendar = .current) {
        file = JSONFileStore(
            fileURL: directory.appending(path: fileName),
            logCategory: "WorkoutPlanStore",
            schemaVersion: Self.schemaVersion,
            decoderUserInfo: [CalendarDay.legacyCalendarKey: calendar]
        )
    }

    func load() throws -> [WorkoutPlan] {
        try file.read() ?? []
    }

    /// Upsert by `id`: replaces the matching plan in place (keeping order) or
    /// appends a new one, then writes the whole file atomically.
    func save(_ plan: WorkoutPlan) throws {
        try file.update(initial: []) { plans in
            if let index = plans.firstIndex(where: { $0.id == plan.id }) {
                plans[index] = plan
            } else {
                plans.append(plan)
            }
        }
    }

    func delete(id: UUID) throws {
        try file.update(initial: []) { $0.removeAll { $0.id == id } }
    }

    /// One atomic write. Refused while the existing file is unreadable.
    func replaceAll(with plans: [WorkoutPlan]) throws {
        try file.write(plans)
    }
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

    func replaceAll(with plans: [WorkoutPlan]) throws {
        self.plans = plans
    }
}
