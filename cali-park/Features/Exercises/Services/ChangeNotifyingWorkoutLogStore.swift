import Foundation

// MARK: - ChangeNotifyingWorkoutLogStore
/// Wraps a `WorkoutLogStoring` and calls `onChange` after every successful
/// write (append or delete). `AppEnvironment` hands this wrapper to every view
/// model, so each save point (SetPad, quick workout, history, session detail,
/// Home) re-syncs plan reminders without knowing about them: finishing today's
/// plan cancels today's pending reminder right away, and deleting that workout
/// brings it back.
struct ChangeNotifyingWorkoutLogStore: WorkoutLogStoring {
    private let base: WorkoutLogStoring
    private let onChange: @Sendable () -> Void

    init(base: WorkoutLogStoring, onChange: @escaping @Sendable () -> Void) {
        self.base = base
        self.onChange = onChange
    }

    func load() throws -> [WorkoutLogEntry] {
        try base.load()
    }

    func append(_ entry: WorkoutLogEntry) throws {
        try base.append(entry)
        onChange()
    }

    func append(contentsOf entries: [WorkoutLogEntry]) throws {
        try base.append(contentsOf: entries)
        onChange()
    }

    func delete(id: UUID) throws {
        try base.delete(id: id)
        onChange()
    }
}
