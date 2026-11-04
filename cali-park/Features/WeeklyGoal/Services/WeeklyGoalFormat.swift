import Foundation

// MARK: - WeeklyGoalFormat
/// Polish copy for weekly goals, kept off the models and testable in one place.
/// Holds show the invariant "s" on screen; spoken variants spell it out.
enum WeeklyGoalFormat {
    // MARK: Goal

    /// The goal in a few words: "3 dni treningowe", "4 treningi z planu",
    /// "Wszystkie zaplanowane treningi", "Podciągnięcia: 75 powtórzeń",
    /// "L-sit: 180 s".
    static func title(_ metric: WeeklyGoal.Metric) -> String {
        switch metric {
        case let .trainingDays(days):
            PolishPlural.trainingDays(days)
        case let .plannedWorkouts(.count(workouts)):
            "\(PolishPlural.workouts(workouts)) z planu"
        case .plannedWorkouts(.allScheduled):
            "Wszystkie zaplanowane treningi"
        case let .exerciseVolume(exerciseID, measurement, amount):
            "\(exerciseName(exerciseID)): \(amountText(amount, measurement))"
        }
    }

    /// `title` for VoiceOver, with seconds spelled out.
    static func spokenTitle(_ metric: WeeklyGoal.Metric) -> String {
        guard case let .exerciseVolume(exerciseID, .seconds, amount) = metric else { return title(metric) }
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
                ? "Brak zaplanowanych treningów"
                : "\(progress.value) / \(PolishPlural.workouts(progress.target))"
        case let .exerciseVolume(_, measurement, _):
            "\(progress.value) / \(amountText(progress.target, measurement))"
        }
    }

    /// `progress` for VoiceOver: "2 z 3", then the unit.
    static func spokenProgress(_ progress: WeeklyGoalProgress) -> String {
        let text = self.progress(progress)
        guard progress.target > 0 else { return text }
        if case .exerciseVolume(_, .seconds, _) = progress.goal.metric {
            return "\(progress.value) z \(PolishPlural.seconds(progress.target))"
        }
        return text.replacingOccurrences(of: " / ", with: " z ")
    }

    // MARK: Week

    /// "Seria: 3 tygodnie".
    static func streak(_ weeks: Int) -> String {
        "Seria: \(PolishPlural.weeks(weeks))"
    }

    /// A short note on the week's verdict, or `nil` for a plain running week.
    static func status(_ week: WeeklyGoalWeek) -> String? {
        switch week.status {
        case .met: "Cel wykonany"
        case .paused: "Pauza"
        case .warmUp: "Tydzień rozgrzewkowy"
        case .nothingScheduled: "Nic nie zaplanowano"
        case .missed: "Cel niewykonany"
        case .inProgress: nil
        }
    }

    /// "Pauza do 12 lis" for an active pause (its last paused day).
    static func pauseLine(_ pause: WeeklyGoalPause, calendar: Calendar = .current) -> String {
        let lastDay = calendar.date(byAdding: .day, value: -1, to: pause.plannedEnd) ?? pause.plannedEnd
        return "Pauza do " + lastDay.formatted(.dateTime.day().month(.abbreviated))
    }

    // MARK: Helpers

    /// "75 powtórzeń" or "180 s".
    static func amountText(_ amount: Int, _ measurement: ExerciseMeasurement) -> String {
        switch measurement {
        case .reps: PolishPlural.reps(amount)
        case .seconds: "\(amount) s"
        }
    }

    static func exerciseName(_ id: UUID) -> String {
        ExerciseCatalog.exercise(withID: id)?.name ?? "Ćwiczenie"
    }
}
