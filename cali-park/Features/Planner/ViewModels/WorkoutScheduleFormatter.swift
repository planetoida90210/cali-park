import Foundation

// MARK: - WorkoutScheduleFormatter
/// Turns a `WorkoutSchedule` into short, human Polish text: the summary for
/// the planner list, the upcoming days for the editor's footer. Presentation logic lives here (not on the model) so
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

    /// The schedule's next few days, for the plan editor's footer, so it
    /// says something its controls don't: "Najbliższe treningi: dziś, 6 lis,
    /// 8 lis", or "Najbliższy trening: jutro" for a one-off plan. `nil` when
    /// nothing is coming up (no weekday picked, a past one-off day).
    static func upcomingDays(
        _ schedule: WorkoutSchedule,
        count: Int = 3,
        asOf reference: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String? {
        let today = calendar.startOfDay(for: reference)
        var days: [Date] = []
        var from = today
        while days.count < count, let next = schedule.nextOccurrence(onOrAfter: from, calendar: calendar) {
            days.append(next)
            // A one-off plan has nothing after its day, so the loop ends there.
            guard let following = calendar.date(byAdding: .day, value: 1, to: next) else { break }
            from = following
        }
        guard !days.isEmpty else { return nil }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
        let labels = days.map { day -> String in
            if day == today { return String(localized: "dziś") }
            if day == tomorrow { return String(localized: "jutro") }
            // "6 lis" never wraps between the day and the month.
            return String(shortDate(day, calendar: calendar, locale: locale).map { $0 == " " ? String.noBreakSpace : $0 })
        }
        let list = labels.joined(separator: ", ")
        return days.count == 1
            ? String(localized: "Najbliższy trening: \(list)")
            : String(localized: "Najbliższe treningi: \(list)")
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
