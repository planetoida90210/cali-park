import Foundation

// MARK: - WorkoutScheduleFormatter
/// Turns a `WorkoutSchedule` into a short, human Polish summary for the planner
/// list and editor footer. Presentation logic lives here (not on the model) so
/// the model stays free of localization concerns.
enum WorkoutScheduleFormatter {
    /// A one-line description, e.g. "Co tydzień · Pon, Czw", "Co 3 dni",
    /// "Codziennie", "Jednorazowo · 20 lip" or "Bez terminu". Month names
    /// follow `locale`, which is Polish in the app (development region `pl`).
    static func summary(
        _ schedule: WorkoutSchedule,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        switch schedule {
        case .once(let day):
            guard let day else { return "Bez terminu" }
            return "Jednorazowo · " + shortDate(day.startDate(in: calendar), calendar: calendar, locale: locale)

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

    /// A short "when" label for a scheduled day: "Dziś", "Jutro", a weekday name
    /// within the coming week ("sobota"), otherwise a day/month date ("20 lip").
    static func dayLabel(
        _ date: Date,
        asOf reference: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: reference)

        if day == today { return "Dziś" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today), day == tomorrow {
            return "Jutro"
        }

        let daysAway = calendar.dateComponents([.day], from: today, to: day).day ?? 0
        if (0...6).contains(daysAway) {
            var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            style = style.weekday(.wide)
            return date.formatted(style)
        }
        return shortDate(date, calendar: calendar, locale: locale)
    }

    /// "20 lip": day and abbreviated month in the calendar's time zone.
    private static func shortDate(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .day()
            .month(.abbreviated)
        return date.formatted(style)
    }
}
