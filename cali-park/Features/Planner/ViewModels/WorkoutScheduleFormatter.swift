import Foundation

// MARK: - WorkoutScheduleFormatter
/// Turns a `WorkoutSchedule` into a short, human Polish summary for the planner
/// list and editor footer. Presentation logic lives here (not on the model) so
/// the model stays free of localization concerns.
enum WorkoutScheduleFormatter {
    /// A one-line description, e.g. "Co tydzień · Pon, Czw", "Co 3 dni",
    /// "Codziennie", "Jednorazowo · 20 lip" or "Bez terminu".
    static func summary(_ schedule: WorkoutSchedule, calendar: Calendar = .current) -> String {
        switch schedule {
        case .once(let date):
            guard let date else { return "Bez terminu" }
            return "Jednorazowo · " + date.formatted(.dateTime.day().month(.abbreviated))

        case .weekly(let days):
            guard !days.isEmpty else { return "Co tydzień" }
            let labels = Weekday.ordered(for: calendar)
                .filter { days.contains($0) }
                .map(\.shortName)
            return "Co tydzień · " + labels.joined(separator: ", ")

        case .everyNDays(let interval, _):
            guard interval > 1 else { return "Codziennie" }
            return "Co \(PolishPlural.days(interval))"
        }
    }
}
