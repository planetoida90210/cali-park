import Foundation
import Observation
import os

// MARK: - WeeklyGoalEditorViewModel
/// Drives the weekly goal editor: a draft of one to three goals (the first is
/// the primary) saved with "Zapisz", plus pausing, which applies at once.
///
/// Reusable: Home opens it from the hero ring and the "Cel tygodniowy" module,
/// and Profile from its weekly goal row.
@MainActor
@Observable
final class WeeklyGoalEditorViewModel: Identifiable {
    // MARK: State
    /// Lets a presenter use `.sheet(item:)`.
    let id = UUID()
    /// The draft, primary goal first.
    private(set) var goals: [WeeklyGoal] = []
    /// The goals as saved (or the implicit default), to detect changes.
    private(set) var savedGoals: [WeeklyGoal] = []
    /// Whether nothing is saved yet, so the default goal applies.
    private(set) var isDefault = true
    /// The pause in force now, if any.
    private(set) var activePause: WeeklyGoalPause?
    /// Set when loading or saving fails, for the editor's alert.
    var errorMessage: String?
    /// Whether the saved goal could not be read. Editing is then blocked: the
    /// store refuses writes, and the draft would not show the real goals.
    private(set) var hasLoadError = false

    // MARK: Dependencies
    private let store: WeeklyGoalStoring
    /// Read on save, to anchor the implicit default at the first workout.
    private let journal: TrainingJournal
    let calendar: Calendar
    private let clock: () -> Date
    private let logger = AppLog.logger(category: "WeeklyGoalEditor")

    // MARK: Init
    init(store: WeeklyGoalStoring,
         journal: TrainingJournal,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.store = store
        self.journal = journal
        self.calendar = calendar
        self.clock = clock
        load()
    }

    // MARK: Loading
    /// Reads the saved goals and pause. A failure keeps the editor read-only.
    func load() {
        do {
            let history = try store.load() ?? .empty
            let now = clock()
            goals = history.currentGoals(at: now)
            savedGoals = goals
            isDefault = history.versions.isEmpty
            activePause = history.activePause(at: now)
            hasLoadError = false
        } catch {
            errorMessage = StoreLoadFailure.message
            hasLoadError = true
        }
    }

    // MARK: Draft state
    var hasUnsavedChanges: Bool { goals != savedGoals }
    var canEdit: Bool { !hasLoadError }
    var canAddGoal: Bool { canEdit && goals.count < WeeklyGoal.maximumCount }
    var canRemoveGoals: Bool { canEdit && goals.count > 1 }
    var canSave: Bool { canEdit && hasUnsavedChanges && WeeklyGoal.isValidSet(goals) }

    func goal(withID id: WeeklyGoal.ID) -> WeeklyGoal? {
        goals.first { $0.id == id }
    }

    func isPrimary(_ id: WeeklyGoal.ID) -> Bool {
        goals.first?.id == id
    }

    // MARK: Draft intentions
    /// Adds a goal of `kind` with its default target; returns its id, or `nil`
    /// when three goals already exist.
    @discardableResult
    func addGoal(_ kind: WeeklyGoal.Kind) -> WeeklyGoal.ID? {
        guard canAddGoal else { return nil }
        let goal = WeeklyGoal(metric: kind.defaultMetric)
        goals.append(goal)
        return goal.id
    }

    /// Replaces one goal's metric; out-of-range targets are ignored.
    func updateMetric(_ metric: WeeklyGoal.Metric, forGoal id: WeeklyGoal.ID) {
        guard canEdit, metric.isValid, let index = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[index].metric = metric
    }

    /// Removes a goal, keeping at least one. Removing the primary promotes the
    /// next goal.
    func removeGoal(_ id: WeeklyGoal.ID) {
        guard canRemoveGoals else { return }
        goals.removeAll { $0.id == id }
    }

    /// Makes a goal the primary one (first in the list).
    func makePrimary(_ id: WeeklyGoal.ID) {
        guard canEdit, let index = goals.firstIndex(where: { $0.id == id }), index > 0 else { return }
        goals.insert(goals.remove(at: index), at: 0)
    }

    /// Saves the draft as the goals from now on (the whole current week
    /// included). Returns whether the editor can close.
    @discardableResult
    func save() -> Bool {
        guard canEdit else { return false }
        guard hasUnsavedChanges else { return true }
        guard WeeklyGoal.isValidSet(goals) else { return false }
        // The implicit default is anchored at the first workout, so an
        // unreadable journal must not pass for an empty one.
        journal.reloadIfFailed()
        let history: WeeklyGoalHistory
        do {
            history = try store.load() ?? .empty
        } catch {
            errorMessage = StoreLoadFailure.message
            return false
        }
        guard !journal.hasLoadFailure else {
            errorMessage = StoreLoadFailure.message
            return false
        }
        let logs = journal.entries
        let now = clock()
        guard let updated = history.settingGoals(
            goals,
            at: now,
            implicitStart: WeeklyGoalEvaluator.implicitStart(entries: logs, asOf: now),
            calendar: calendar
        ) else { return false }
        do {
            if updated != history { try store.save(updated) }
        } catch {
            logger.error("Cannot save weekly goal: \(String(describing: error), privacy: .public)")
            errorMessage = Self.saveFailureMessage
            return false
        }
        savedGoals = goals
        isDefault = updated.versions.isEmpty
        return true
    }

    /// Drops the draft and returns to the saved goals.
    func discardChanges() {
        goals = savedGoals
    }

    // MARK: Pause
    /// How long a new pause lasts.
    enum PauseLength: Hashable {
        case week
        case month
        /// Through the given day (its last paused day).
        case through(Date)
    }

    /// The days a custom pause may end on: today through day 90.
    var customPauseRange: ClosedRange<Date> {
        let today = calendar.startOfDay(for: clock())
        let last = calendar.date(byAdding: .day, value: WeeklyGoalPause.maximumDays - 1, to: today) ?? today
        return today...last
    }

    /// Starts a pause from today; it applies at once (no "Zapisz").
    func startPause(_ length: PauseLength) {
        guard canEdit else { return }
        let now = clock()
        let today = calendar.startOfDay(for: now)
        let end: Date? = switch length {
        case .week: calendar.date(byAdding: .day, value: 7, to: today)
        case .month: calendar.date(byAdding: .month, value: 1, to: today)
        case let .through(lastDay): calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastDay))
        }
        guard let end else { return }
        updateHistory { $0.startingPause(at: now, until: end, calendar: calendar) }
    }

    /// Ends the active pause now.
    func endPause() {
        guard canEdit else { return }
        let now = clock()
        updateHistory { $0.endingPause(at: now) }
    }

    /// Re-reads the history, applies `change` and saves the result, so a
    /// pause never overwrites changes made elsewhere.
    private func updateHistory(_ change: (WeeklyGoalHistory) -> WeeklyGoalHistory?) {
        let history: WeeklyGoalHistory
        do {
            history = try store.load() ?? .empty
        } catch {
            errorMessage = StoreLoadFailure.message
            hasLoadError = true
            return
        }
        guard let updated = change(history) else { return }
        do {
            try store.save(updated)
            activePause = updated.activePause(at: clock())
        } catch {
            logger.error("Cannot update weekly goal pause: \(String(describing: error), privacy: .public)")
            errorMessage = Self.saveFailureMessage
        }
    }

    static let saveFailureMessage = "Nie udało się zapisać celu. Spróbuj ponownie."
}
