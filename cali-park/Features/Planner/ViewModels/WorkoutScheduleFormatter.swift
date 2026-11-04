import Foundation

// MARK: - WorkoutScheduleFormatter
/// Turns a `WorkoutSchedule` into a short, human Polish summary for the planner
/// list and editor footer. Presentation logic lives here (not on the model) so
/// the model stays free of localization concerns.
nonisolated enum WorkoutScheduleFormatter {
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
            guard let day else { return String(localized: "Bez terminu") }
            let dateText = shortDate(day.startDate(in: calendar), calendar: calendar, locale: locale)
            return String(localized: "Jednorazowo · \(dateText)")

        case .weekly(let days):
            guard !days.isEmpty else { return String(localized: "Co tydzień") }
            let labels = Weekday.ordered(for: calendar)
                .filter { days.contains($0) }
                .map(\.shortName)
            let daysText = labels.joined(separator: ", ")
            return String(localized: "Co tydzień · \(daysText)")

        case .everyNDays(let interval, _):
            guard interval > 1 else { return String(localized: "Codziennie") }
            return String(localized: "Co \(PolishPlural.days(interval))")
        }
    }

    /// The plans list's line: `summary`, except that a one-off plan whose day
    /// has passed reads "Minął · 10 lis", so it doesn't look upcoming.
    static func listSummary(
        _ schedule: WorkoutSchedule,
        asOf reference: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        guard schedule.isExpired(asOf: reference, calendar: calendar),
              case .once(let day?) = schedule
        else { return summary(schedule, calendar: calendar, locale: locale) }
        let dateText = shortDate(day.startDate(in: calendar), calendar: calendar, locale: locale)
        return String(localized: "Minął · \(dateText)")
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

        if day == today { return String(localized: "Dziś") }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today), day == tomorrow {
            return String(localized: "Jutro")
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
