import Foundation
import Observation

// MARK: - PlanEditorViewModel
/// Drives creating and editing a `WorkoutPlan`: name, its exercises, and a
/// single mutually-exclusive recurrence mode. Editing loads an existing plan;
/// a `nil` plan starts a fresh one. Also sets the plan's optional reminder
/// (toggle + time), asking for notification permission the first time it is
/// turned on. Saving goes through `WorkoutPlanService`, which re-syncs
/// reminders.
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
            case .weekly: String(localized: "Co tydzień")
            case .everyNDays: String(localized: "Co N dni")
            case .once: String(localized: "Jednorazowo")
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
    /// Chosen day for a one-off plan, at the start of the day. Must be today
    /// or later to save (`isOnceDateInPast`).
    var onceDate: Date
    /// Whether the plan sends a local reminder on its days. Turn it on through
    /// `setReminderEnabled(_:)`, which handles notification permission.
    private(set) var reminderEnabled: Bool
    /// The reminder's time of day; only its hour and minute are used.
    var reminderTime: Date
    /// Notifications are off for the app, so a reminder can't be delivered.
    /// The editor then explains it and links to Settings.
    private(set) var showsNotificationsDeniedHint = false

    var errorMessage: String?
    /// Set after a successful save so the editor can dismiss itself.
    private(set) var didSave = false
    /// A save is in flight; blocks a second tap from saving twice.
    private(set) var isSaving = false
    /// The plan was saved a moment ago by "Utwórz plan" and opened here for a
    /// first look, so "Anuluj" deletes it instead of leaving it behind.
    let isJustCreated: Bool

    // MARK: Dependencies & identity
    private let service: WorkoutPlanService
    private let calendar: Calendar
    /// The start of the day the editor opened on.
    private let today: Date
    /// The plan being edited, or a blank one for a new plan. `save()` edits a
    /// copy of it, so its identity and every field this editor does not show
    /// (`isActive`, `createdAt`, exercise targets, …) survive.
    private let original: WorkoutPlan
    /// Anchor for `everyNDays`; kept from the existing plan, else today.
    private let intervalAnchor: CalendarDay
    /// The earliest day the one-off date picker offers: today, or the plan's
    /// own past date when an expired one-off plan is edited, so the picker
    /// can still show it.
    let earliestOnceDate: Date
    /// The editable fields as the editor opened them, for `hasUnsavedChanges`.
    @ObservationIgnored private var baseline: Draft?

    /// The editable part of a plan, compared to tell whether anything changed.
    private struct Draft: Equatable {
        let name: String
        let exercises: [PlannedExercise]
        let schedule: WorkoutSchedule
        let reminder: DateComponents?
    }

    // MARK: Init
    init(plan: WorkoutPlan?,
         service: WorkoutPlanService,
         isJustCreated: Bool = false,
         calendar: Calendar = .current,
         now: Date = .now) {
        self.service = service
        self.isJustCreated = isJustCreated && plan != nil
        self.calendar = calendar
        let today = calendar.startOfDay(for: now)
        self.today = today
        let original = plan ?? WorkoutPlan(name: "", schedule: .weekly([]), createdAt: now)
        self.original = original

        name = original.name
        exercises = original.exercises
        scheduleMode = .weekly
        selectedWeekdays = []
        interval = 2
        onceDate = today
        if let time = original.reminderTime, let hour = time.hour, let minute = time.minute {
            reminderEnabled = true
            reminderTime = Self.time(hour: hour, minute: minute, on: today, calendar: calendar)
        } else {
            reminderEnabled = false
            reminderTime = Self.time(hour: Self.defaultReminderHour, minute: 0, on: today, calendar: calendar)
        }
        if case .everyNDays(_, let anchor) = original.schedule {
            intervalAnchor = anchor
        } else {
            intervalAnchor = CalendarDay(today, in: calendar)
        }

        var earliestOnceDate = today
        switch original.schedule {
        case .weekly(let days):
            selectedWeekdays = days
        case .everyNDays(let value, _):
            scheduleMode = .everyNDays
            interval = value
        case .once(let day):
            scheduleMode = .once
            // An expired one-off plan opens on its own past date: the editor
            // then says why it can't be saved as is.
            let date = day?.startDate(in: calendar) ?? today
            onceDate = date
            earliestOnceDate = min(today, date)
        }
        self.earliestOnceDate = earliestOnceDate

        baseline = draft
    }

    // MARK: Derived state
    private var draft: Draft {
        Draft(name: trimmedName, exercises: exercises, schedule: schedule, reminder: reminderComponents)
    }

    /// Whether closing now would lose an edit: the name, exercises, the
    /// resulting schedule or the reminder differ from how the editor opened, and nothing is
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
        case .once: .once(CalendarDay(onceDate, in: calendar))
        }
    }

    /// The one-off date is before today, so the plan would never occur.
    var isOnceDateInPast: Bool {
        CalendarDay(onceDate, in: calendar) < CalendarDay(today, in: calendar)
    }

    /// Why a one-off plan can't be saved, shown under the schedule; `nil`
    /// when there is nothing to fix.
    var scheduleProblem: String? {
        guard scheduleMode == .once, isOnceDateInPast else { return nil }
        return String(localized: "Ta data już minęła. Wybierz dziś lub dzień w przyszłości – inaczej plan się nie odbędzie.")
    }

    /// Hour and minute of the reminder, or `nil` when it is off. Keeps the
    /// plan's stored value when the time is unchanged, so an untouched plan
    /// saves back exactly as it was.
    var reminderComponents: DateComponents? {
        guard reminderEnabled else { return nil }
        let picked = calendar.dateComponents([.hour, .minute], from: reminderTime)
        if let stored = original.reminderTime, stored.hour == picked.hour, stored.minute == picked.minute {
            return stored
        }
        return DateComponents(hour: picked.hour, minute: picked.minute)
    }

    /// A weekly plan needs at least one day; an interval must be positive; a
    /// one-off day can't be in the past. Without this a plan could be saved
    /// with no possible occurrence.
    private var hasValidSchedule: Bool {
        switch scheduleMode {
        case .weekly: !selectedWeekdays.isEmpty
        case .everyNDays: interval > 0
        case .once: !isOnceDateInPast
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

    /// "Anuluj": for a plan "Utwórz plan" just saved, deletes it through
    /// `WorkoutPlanService` (which re-syncs reminders). Returns whether the
    /// editor may close; on a failed delete it shows an error and stays.
    func cancel() async -> Bool {
        guard isJustCreated, !didSave else { return true }
        do {
            try await service.delete(id: original.id)
            return true
        } catch {
            errorMessage = String(localized: "Nie udało się usunąć planu.")
            return false
        }
    }

    // MARK: Program origin
    /// The ready-made program the plan was created from, or `nil` for a plan
    /// the user built.
    var program: TrainingProgram? {
        ProgramCatalog.program(for: original)
    }

    /// "Program Fundamenty · wersja 1" plus the program's credit line, for a
    /// plan created from a program.
    var programOrigin: (line: String, credit: String)? {
        program.map { (ProgramFormat.originLine(for: $0, version: original.programVersion), $0.creditLine) }
    }

    /// What to do on an item, e.g. "3 × 5–8 · przerwa 90 s", or `nil` for an
    /// item without targets.
    func targetSummary(for planned: PlannedExercise) -> String? {
        let parts = [
            ProgramFormat.groupLabel(for: planned, in: exercises),
            ProgramFormat.doseSummary(for: planned, exercise: exercise(for: planned)),
            ProgramFormat.restSummary(for: planned)
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The ladder an item follows ("Podciąganie"), or `nil` for a fixed
    /// exercise. Such an item trains the athlete's current rung when a
    /// session starts.
    func ladderName(for planned: PlannedExercise) -> String? {
        planned.pathID.flatMap(ProgressionCatalog.path(withID:))?.name
    }

    /// The plan `save()` would store: the original with only the edited
    /// fields replaced.
    var editedPlan: WorkoutPlan {
        var plan = original
        plan.name = trimmedName
        plan.exercises = exercises
        plan.schedule = schedule
        plan.reminderTime = reminderComponents
        return plan
    }

    /// Turns the reminder on or off. Turning it on checks notification
    /// permission and asks for it while it is undetermined (so the system
    /// prompt appears on the first enable only). When notifications are
    /// denied the reminder stays off and the denied hint shows.
    func setReminderEnabled(_ enabled: Bool) async {
        guard enabled else {
            reminderEnabled = false
            showsNotificationsDeniedHint = false
            return
        }
        reminderEnabled = true

        let granted: Bool
        switch await service.reminderAuthorizationStatus() {
        case .authorized: granted = true
        case .denied: granted = false
        case .notDetermined: granted = await service.requestReminderAuthorization()
        }
        // Turned off again while the permission prompt was up.
        guard reminderEnabled else { return }
        reminderEnabled = granted
        showsNotificationsDeniedHint = !granted
    }

    /// Shows the denied hint when the plan already has a reminder but
    /// notifications were turned off in Settings. Call when the editor opens.
    func refreshNotificationPermission() async {
        guard reminderEnabled else { return }
        showsNotificationsDeniedHint = await service.reminderAuthorizationStatus() == .denied
    }

    /// Saves the plan and re-syncs reminders. No-op unless `canSave`, or while
    /// a save is already running. When the plan saved but its reminders
    /// could not be set, `didSave` is set and `errorMessage` explains.
    func save() async {
        guard canSave, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let reminders = try await service.save(editedPlan)
            if reminders == .failed, reminderComponents != nil || original.reminderTime != nil {
                errorMessage = String(localized: "Plan zapisany, ale nie udało się ustawić przypomnienia.")
            }
            didSave = true
        } catch {
            errorMessage = String(localized: "Nie udało się zapisać planu.")
        }
    }

    // MARK: Helpers

    /// Default reminder time when a plan has none yet: 18:00.
    private static let defaultReminderHour = 18

    private static func time(hour: Int, minute: Int, on day: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}
