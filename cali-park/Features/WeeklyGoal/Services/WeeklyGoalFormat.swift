import Foundation

// MARK: - WeeklyGoalFormat
/// Polish copy for weekly goals, kept off the models and testable in one place.
/// Holds show the invariant "s" on screen; spoken variants spell it out.
nonisolated enum WeeklyGoalFormat {
    // MARK: Goal

    /// The goal in a few words: "3 dni treningowe", "4 treningi z planu",
    /// "Wszystkie zaplanowane treningi", "Podciągnięcia: 75 powtórzeń",
    /// "L-sit: 180 s".
    static func title(_ metric: WeeklyGoal.Metric) -> String {
        switch metric {
        case .trainingDays(let days):
            PolishPlural.trainingDays(days)
        case .plannedWorkouts(.count(let workouts)):
            String(localized: "\(PolishPlural.workouts(workouts)) z planu")
        case .plannedWorkouts(.allScheduled):
            String(localized: "Wszystkie zaplanowane treningi")
        case .exerciseVolume(let exerciseID, let measurement, let amount):
            "\(exerciseName(exerciseID)): \(amountText(amount, measurement))"
        }
    }

    /// The editor row's second line, only where it adds to `title`: the
    /// volume goal says it counts the week's volume. "3 dni treningowe" and
    /// "4 treningi z planu" already name their kind, so they get none.
    static func editorSubtitle(_ metric: WeeklyGoal.Metric) -> String? {
        switch metric {
        case .trainingDays, .plannedWorkouts: nil
        case .exerciseVolume: String(localized: "Objętość w tygodniu")
        }
    }

    /// `title` for VoiceOver, with seconds spelled out.
    static func spokenTitle(_ metric: WeeklyGoal.Metric) -> String {
        guard case .exerciseVolume(let exerciseID, .seconds, let amount) = metric else { return title(metric) }
        return "\(exerciseName(exerciseID)): \(PolishPlural.seconds(amount))"
    }

    // MARK: Progress

    /// Done against the target, the unit agreeing with the target: "2 / 3 dni",
    /// "1 / 4 treningi", "45 / 75 powtórzeń", "60 / 180 s". "All scheduled"
    /// with nothing scheduled reads "Brak zaplanowanych treningów".
    static func progress(_ progress: WeeklyGoalProgress) -> String {
        switch progress.goal.metric {
        case .trainingDays:
            "\(progress.value) / \(PolishPlural.days(progress.target))"
        case .plannedWorkouts:
            progress.target == 0
                ? String(localized: "Brak zaplanowanych treningów")
                : "\(progress.value) / \(PolishPlural.workouts(progress.target))"
        case .exerciseVolume(_, let measurement, _):
            "\(progress.value) / \(amountText(progress.target, measurement))"
        }
    }

    /// `progress` for VoiceOver: "2 z 3", then the unit.
    static func spokenProgress(_ progress: WeeklyGoalProgress) -> String {
        guard progress.target > 0 else { return self.progress(progress) }
        let target =
            switch progress.goal.metric {
            case .trainingDays: PolishPlural.days(progress.target)
            case .plannedWorkouts: PolishPlural.workouts(progress.target)
            case .exerciseVolume(_, .seconds, _): PolishPlural.seconds(progress.target)
            case .exerciseVolume(_, let measurement, _): amountText(progress.target, measurement)
            }
        return String(localized: "\(progress.value) z \(target)")
    }

    // MARK: Week

    /// "Seria: 3 tygodnie".
    static func streak(_ weeks: Int) -> String {
        String(localized: "Seria: \(PolishPlural.weeks(weeks))")
    }

    /// A short note on the week's verdict, or `nil` for a plain running week.
    static func status(_ week: WeeklyGoalWeek) -> String? {
        switch week.status {
        case .met: String(localized: "Cel wykonany")
        case .paused: String(localized: "Pauza")
        case .warmUp: String(localized: "Tydzień rozgrzewkowy")
        case .nothingScheduled: String(localized: "Nic nie zaplanowano")
        case .missed: String(localized: "Cel niewykonany")
        case .inProgress: nil
        }
    }

    /// "Pauza do 12 lis" for an active pause (its last paused day).
    static func pauseLine(_ pause: WeeklyGoalPause, calendar: Calendar = .current) -> String {
        let lastDay = calendar.date(byAdding: .day, value: -1, to: pause.plannedEnd) ?? pause.plannedEnd
        let dateText = lastDay.formatted(.dateTime.day().month(.abbreviated))
        return String(localized: "Pauza do \(dateText)")
    }

    // MARK: Helpers

    /// "75 powtórzeń" or "180 s".
    static func amountText(_ amount: Int, _ measurement: ExerciseMeasurement) -> String {
        switch measurement {
        case .reps: PolishPlural.reps(amount)
        case .seconds: String(localized: "\(amount) s").keptTogether
        }
    }

    static func exerciseName(_ id: UUID) -> String {
        ExerciseCatalog.exercise(withID: id)?.name ?? String(localized: "Ćwiczenie")
    }
}
