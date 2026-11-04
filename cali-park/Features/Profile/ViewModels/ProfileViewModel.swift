import Foundation
import Observation

// MARK: - ProfileViewModel
/// Drives the Profile tab: statistics (workouts, day and week streaks, level
/// and XP) and the weekly goal summary. A read-only projection of the shared
/// journal, progress and weekly goal, so a workout saved on any tab shows up
/// here by observation.
@MainActor
@Observable
final class ProfileViewModel {
    // MARK: State
    /// Set when the journal or the goal fails to load, for the Profile alert.
    var errorMessage: String?
    /// Whether the current failure streak was already announced.
    @ObservationIgnored private var hasAlertedLoadError = false

    // MARK: Dependencies
    private let journal: TrainingJournal
    private let progress: ProgressService
    private let goals: WeeklyGoalService
    let calendar: Calendar
    private let clock: () -> Date

    // MARK: Init
    init(journal: TrainingJournal,
         progress: ProgressService,
         goals: WeeklyGoalService,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.journal = journal
        self.progress = progress
        self.goals = goals
        self.calendar = calendar
        self.clock = clock
        alertIfLoadFailed()
    }

    // MARK: Output
    /// The numbers at the top. While the journal can't be read they show what
    /// it last held (nothing, on the first load), next to the alert.
    var statistics: ProfileStatistics {
        let streak = WorkoutStreak.compute(from: journal.entries.map(\.date), calendar: calendar, today: clock())
        return ProfileStatistics(
            workouts: WorkoutSession.grouped(from: journal.entries).count,
            dayStreak: streak.current,
            longestDayStreak: streak.longest,
            weekStreak: goals.snapshot?.streak,
            level: progress.snapshot.level
        )
    }

    /// The weekly goal now; `nil` while it cannot be read.
    var weeklyGoal: WeeklyGoalSnapshot? { goals.snapshot }

    /// Whether the journal or the weekly goal could not be read.
    var hasLoadError: Bool { journal.hasLoadFailure || goals.loadFailure != nil }

    /// "2 / 3 dni" for the primary goal, or a pause line.
    var weeklyGoalProgressText: String? {
        guard let weeklyGoal else { return nil }
        if let pause = weeklyGoal.activePause {
            return WeeklyGoalFormat.pauseLine(pause, calendar: calendar)
        }
        return WeeklyGoalFormat.progress(weeklyGoal.week.primary)
    }

    /// "3 dni treningowe" — what the primary goal asks for.
    var weeklyGoalTitle: String? {
        weeklyGoal.map { WeeklyGoalFormat.title($0.week.primary.goal.metric) }
    }

    // MARK: Intentions
    /// Retries what failed to load and moves the weekly goal to now. Call on
    /// appear, on return to the app and after the goal editor closes.
    func reload() {
        journal.reloadIfFailed()
        goals.reload()
        alertIfLoadFailed()
    }

    private func alertIfLoadFailed() {
        guard hasLoadError else {
            hasAlertedLoadError = false
            return
        }
        if !hasAlertedLoadError { errorMessage = StoreLoadFailure.message }
        hasAlertedLoadError = true
    }
}
