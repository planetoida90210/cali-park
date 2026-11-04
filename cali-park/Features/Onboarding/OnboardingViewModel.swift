import Foundation
import Observation
import os

// MARK: - OnboardingPage
/// The first-run steps, in order (ticket 026). There is no goals question
/// (the program choice took its role) and no location step (the map asks
/// when it first opens).
nonisolated enum OnboardingPage: Int, CaseIterable, Comparable, Sendable {
    case welcome
    case placement
    case program
    case weeklyGoal

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var next: OnboardingPage? { Self(rawValue: rawValue + 1) }
    var previous: OnboardingPage? { Self(rawValue: rawValue - 1) }
    var isLast: Bool { next == nil }
}

// MARK: - OnboardingViewModel
/// Drives the first-run flow: Powitanie → level test → "Program na start" →
/// weekly goal.
///
/// The program suggestion follows the level test until the athlete picks a
/// program, and the weekly goal ("N dni w tygodniu") follows the chosen
/// program's frequency (3 days for "Bez programu") until the athlete changes
/// it. Finishing saves, in this order: the placement (so the program's plans
/// start on the declared rungs), the program's plans, then the weekly goal.
@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: State
    private(set) var page: OnboardingPage = .welcome
    let calibration: PlacementCalibrationViewModel
    let programChoice: ProgramChoiceViewModel
    /// Training days per week for the weekly goal step.
    private(set) var trainingDays = WeeklyGoal.defaultTrainingDays
    private(set) var isFinishing = false
    /// What could not be saved on finish, for the alert that closes onboarding.
    var errorMessage: String?

    /// Whether the athlete set the days themselves; the program then no
    /// longer overrides them.
    private var hasEditedTrainingDays = false

    // MARK: Dependencies
    private let goalStore: WeeklyGoalStoring
    /// Reloaded after the goal is saved, so Home shows it at once.
    private let goals: WeeklyGoalService?
    /// Read on finish, to anchor the goal at the first logged workout.
    private let journal: TrainingJournal
    private let calendar: Calendar
    private let clock: () -> Date
    private let logger = AppLog.logger(category: "Onboarding")

    // MARK: Init
    init(calibration: PlacementCalibrationViewModel,
         programChoice: ProgramChoiceViewModel,
         goalStore: WeeklyGoalStoring,
         goals: WeeklyGoalService?,
         journal: TrainingJournal,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.calibration = calibration
        self.programChoice = programChoice
        self.goalStore = goalStore
        self.goals = goals
        self.journal = journal
        self.calendar = calendar
        self.clock = clock
    }

    // MARK: Navigation
    /// Moves to `page`, refreshing what depends on earlier answers: the
    /// program suggestion on the program step, the default training days on
    /// the goal step.
    func show(_ page: OnboardingPage) {
        self.page = page
        switch page {
        case .program:
            programChoice.updateSuggestion(for: calibration.placement)
        case .weeklyGoal where !hasEditedTrainingDays:
            trainingDays = suggestedTrainingDays
        default:
            break
        }
    }

    func goForward() {
        if let next = page.next { show(next) }
    }

    func goBack() {
        if let previous = page.previous { show(previous) }
    }

    // MARK: Weekly goal
    /// The chosen program's sessions per week, or 3 without a program.
    var suggestedTrainingDays: Int {
        guard case .program(let id) = programChoice.choice,
              let program = ProgramCatalog.program(withID: id) else {
            return WeeklyGoal.defaultTrainingDays
        }
        return program.weekdays.count
    }

    /// Sets the goal's days, clamped to 1–7.
    func setTrainingDays(_ days: Int) {
        let range = WeeklyGoal.trainingDaysRange
        trainingDays = min(max(days, range.lowerBound), range.upperBound)
        hasEditedTrainingDays = true
    }

    /// The name of the chosen program for the goal step's hint, or `nil`.
    var chosenProgramName: String? {
        guard case .program(let id) = programChoice.choice else { return nil }
        return ProgramCatalog.program(withID: id)?.name
    }

    // MARK: Finish
    /// Saves the placement, the chosen program's plans and the weekly goal,
    /// in that order. Returns `true` when everything was saved; otherwise sets
    /// `errorMessage` (the alert finishes onboarding when closed). A failed
    /// step never stops the later ones: the athlete gets as much as could be
    /// saved.
    func finish() async -> Bool {
        guard !isFinishing else { return false }
        isFinishing = true
        defer { isFinishing = false }

        var problems: [String] = []
        calibration.save()
        if let message = calibration.errorMessage {
            problems.append(message)
            calibration.errorMessage = nil
        }
        if !(await programChoice.createChosenProgram()), let message = programChoice.errorMessage {
            problems.append(message)
            programChoice.errorMessage = nil
        }
        if !saveWeeklyGoal() {
            problems.append("Nie udało się zapisać celu tygodniowego. Ustawisz go później w Profilu.")
        }

        guard problems.isEmpty else {
            errorMessage = problems.joined(separator: "\n\n")
            return false
        }
        return true
    }

    /// Saves "N training days a week" from now on.
    private func saveWeeklyGoal() -> Bool {
        let now = clock()
        do {
            let history = try goalStore.load() ?? .empty
            let start = WeeklyGoalEvaluator.implicitStart(entries: journal.entries, asOf: now)
            guard let updated = history.settingGoals(
                WeeklyGoal.defaultGoals(trainingDaysPerWeek: trainingDays),
                at: now, implicitStart: start, calendar: calendar
            ) else { return false }
            if updated != history { try goalStore.save(updated) }
            goals?.reload()
            return true
        } catch {
            logger.error("Cannot save the onboarding weekly goal: \(String(describing: error), privacy: .public)")
            return false
        }
    }
}
