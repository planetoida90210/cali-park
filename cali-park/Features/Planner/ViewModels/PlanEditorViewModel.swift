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
    /// The plan being edited, or a blank one for a new plan. `save()` edits a
    /// copy of it, so its identity and every field this editor does not show
    /// (`isActive`, `createdAt`, `reminderTime`, exercise targets, …) survive.
    private let original: WorkoutPlan
    /// Anchor for `everyNDays`; kept from the existing plan, else today.
    private let intervalAnchor: Date
    /// The editable fields as the editor opened them, for `hasUnsavedChanges`.
    @ObservationIgnored private var baseline: Draft?

    /// The editable part of a plan, compared to tell whether anything changed.
    private struct Draft: Equatable {
        let name: String
        let exercises: [PlannedExercise]
        let schedule: WorkoutSchedule
    }

    // MARK: Init
    init(plan: WorkoutPlan?, store: WorkoutPlanStoring, calendar: Calendar = .current, now: Date = .now) {
        self.store = store
        let today = calendar.startOfDay(for: now)
        let original = plan ?? WorkoutPlan(name: "", schedule: .weekly([]), createdAt: now)
        self.original = original

        name = original.name
        exercises = original.exercises
        scheduleMode = .weekly
        selectedWeekdays = []
        interval = 2
        onceDate = today
        if case .everyNDays(_, let anchor) = original.schedule {
            intervalAnchor = anchor
        } else {
            intervalAnchor = today
        }

        switch original.schedule {
        case .weekly(let days):
            selectedWeekdays = days
        case .everyNDays(let value, _):
            scheduleMode = .everyNDays
            interval = value
        case .once(let date):
            scheduleMode = .once
            onceDate = date ?? today
        }

        baseline = draft
    }

    // MARK: Derived state
    private var draft: Draft {
        Draft(name: trimmedName, exercises: exercises, schedule: schedule)
    }

    /// Whether closing now would lose an edit: the name, exercises or the
    /// resulting schedule differ from how the editor opened, and nothing is
    /// saved yet. Flipping a mode back and forth is not a change.
    var hasUnsavedChanges: Bool { !didSave && draft != baseline }

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

    /// The plan `save()` would store: the original with only the edited
    /// fields replaced.
    var editedPlan: WorkoutPlan {
        var plan = original
        plan.name = trimmedName
        plan.exercises = exercises
        plan.schedule = schedule
        return plan
    }

    /// Upserts the plan through the store. No-op unless `canSave`.
    func save() {
        guard canSave else { return }

        let plan = editedPlan

        do {
            try store.save(plan)
            didSave = true
        } catch {
            errorMessage = "Nie udało się zapisać planu."
        }
    }
}
