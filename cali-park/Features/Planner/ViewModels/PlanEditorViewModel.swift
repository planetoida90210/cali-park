import Foundation
import Observation

// MARK: - PlanEditorViewModel
/// Drives creating and editing a `WorkoutPlan`: name, its exercises, and a
/// single mutually-exclusive recurrence mode. Editing loads an existing plan;
/// a `nil` plan starts a fresh one. Saving upserts through `WorkoutPlanStoring`.
@MainActor
@Observable
final class PlanEditorViewModel {
    // MARK: ScheduleMode
    /// One recurrence choice at a time (segmented control), never independent
    /// toggles (see swiftui-design-principles: "Mutually exclusive options").
    enum ScheduleMode: String, CaseIterable, Identifiable {
        case weekly
        case everyNDays
        case once

        var id: String { rawValue }

        var title: String {
            switch self {
            case .weekly: "Co tydzień"
            case .everyNDays: "Co N dni"
            case .once: "Jednorazowo"
            }
        }
    }

    // MARK: Editable state
    var name: String
    private(set) var exercises: [PlannedExercise]
    var scheduleMode: ScheduleMode
    var selectedWeekdays: Set<Weekday>
    /// Interval for `everyNDays`, clamped to a sensible range by the stepper.
    var interval: Int
    /// Chosen day for a one-off plan.
    var onceDate: Date

    var errorMessage: String?
    /// Set after a successful save so the editor can dismiss itself.
    private(set) var didSave = false

    // MARK: Dependencies & identity
    private let store: WorkoutPlanStoring
    /// Preserved across an edit so `save()` upserts instead of duplicating.
    private let planID: UUID
    private let createdAt: Date
    private let isActive: Bool
    /// Anchor for `everyNDays`; kept from the existing plan, else today.
    private let intervalAnchor: Date

    // MARK: Init
    init(plan: WorkoutPlan?, store: WorkoutPlanStoring, calendar: Calendar = .current) {
        self.store = store
        let today = calendar.startOfDay(for: .now)

        guard let plan else {
            planID = UUID()
            createdAt = .now
            isActive = true
            name = ""
            exercises = []
            scheduleMode = .weekly
            selectedWeekdays = []
            interval = 2
            onceDate = today
            intervalAnchor = today
            return
        }

        planID = plan.id
        createdAt = plan.createdAt
        isActive = plan.isActive
        name = plan.name
        exercises = plan.exercises

        switch plan.schedule {
        case .weekly(let days):
            scheduleMode = .weekly
            selectedWeekdays = days
            interval = 2
            onceDate = today
            intervalAnchor = today
        case .everyNDays(let value, let anchor):
            scheduleMode = .everyNDays
            selectedWeekdays = []
            interval = value
            onceDate = today
            intervalAnchor = anchor
        case .once(let date):
            scheduleMode = .once
            selectedWeekdays = []
            interval = 2
            onceDate = date ?? today
            intervalAnchor = today
        }
    }

    // MARK: Derived state
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The schedule assembled from the current mode and its inputs.
    var schedule: WorkoutSchedule {
        switch scheduleMode {
        case .weekly: .weekly(selectedWeekdays)
        case .everyNDays: .everyNDays(interval, from: intervalAnchor)
        case .once: .once(onceDate)
        }
    }

    /// A weekly plan needs at least one day; an interval must be positive.
    /// Without this a plan could be saved with no possible occurrence.
    private var hasValidSchedule: Bool {
        switch scheduleMode {
        case .weekly: !selectedWeekdays.isEmpty
        case .everyNDays: interval > 0
        case .once: true
        }
    }

    /// Save is allowed with a non-empty name, at least one exercise, and a
    /// schedule that can actually occur.
    var canSave: Bool {
        !trimmedName.isEmpty && !exercises.isEmpty && hasValidSchedule
    }

    // MARK: Intentions
    /// Adds an exercise once; a plan lists each movement a single time.
    func addExercise(_ exercise: Exercise) {
        guard !exercises.contains(where: { $0.exerciseID == exercise.id }) else { return }
        exercises.append(PlannedExercise(exerciseID: exercise.id))
    }

    func remove(atOffsets offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    func remove(_ planned: PlannedExercise) {
        exercises.removeAll { $0.id == planned.id }
    }

    func toggle(_ weekday: Weekday) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    /// Resolves the catalog exercise a planned entry points to.
    func exercise(for planned: PlannedExercise) -> Exercise? {
        ExerciseCatalog.exercise(withID: planned.exerciseID)
    }

    /// Upserts the plan through the store. No-op unless `canSave`.
    func save() {
        guard canSave else { return }

        let plan = WorkoutPlan(
            id: planID,
            name: trimmedName,
            exercises: exercises,
            schedule: schedule,
            isActive: isActive,
            createdAt: createdAt
        )

        do {
            try store.save(plan)
            didSave = true
        } catch {
            errorMessage = "Nie udało się zapisać planu. Spróbuj ponownie."
        }
    }
}
