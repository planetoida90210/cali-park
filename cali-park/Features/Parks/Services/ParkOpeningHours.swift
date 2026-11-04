import Foundation

// MARK: - ParkOpeningHours
/// Readable Polish text for the OSM `opening_hours` value of a Park.
///
/// Only the simple forms common on Parks are translated: `24/7`, and rules
/// made of weekdays and time ranges, such as `Mo-Su 06:00-22:00` or
/// `Mo-Fr 10:00-22:00; Sa,Su 08:00-20:00`. Anything else (holidays, months,
/// sunrise, comments…) comes back unchanged, because a wrong translation is
/// worse than the raw value.
nonisolated enum ParkOpeningHours {
    /// "Całą dobę", "Codziennie 6:00–22:00", "Pon.–pt. 10:00–22:00", or the
    /// raw value when it isn't one of the simple forms.
    static func text(for raw: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return translate(value) ?? value
    }

    /// The readable text, or nil when the value isn't one of the simple forms.
    static func translate(_ raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if value == "24/7" { return allDay }

        let rules = value.split(separator: ";", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        guard !rules.contains(where: \.isEmpty) else { return nil }
        var texts: [String] = []
        for rule in rules {
            guard let text = translate(rule: rule) else { return nil }
            texts.append(text)
        }
        let joined = texts.joined(separator: "; ")
        return joined.prefix(1).uppercased() + joined.dropFirst()
    }

    // MARK: Rules

    private static let allDay = String(localized: "Całą dobę")
    private static let everyDay = String(localized: "codziennie")

    /// OSM weekday keys in order, with their Polish abbreviations.
    private static let weekdays: [(key: String, label: String)] = [
        ("Mo", String(localized: "pon.", comment: "Monday, abbreviated, in opening hours")),
        ("Tu", String(localized: "wt.", comment: "Tuesday, abbreviated, in opening hours")),
        ("We", String(localized: "śr.", comment: "Wednesday, abbreviated, in opening hours")),
        ("Th", String(localized: "czw.", comment: "Thursday, abbreviated, in opening hours")),
        ("Fr", String(localized: "pt.", comment: "Friday, abbreviated, in opening hours")),
        ("Sa", String(localized: "sob.", comment: "Saturday, abbreviated, in opening hours")),
        ("Su", String(localized: "niedz.", comment: "Sunday, abbreviated, in opening hours"))
    ]

    /// One rule: `[weekdays] times`, where times are ranges or `off`.
    private static func translate(rule: String) -> String? {
        let parts = rule.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        switch parts.count {
        case 1:
            // Times only: every day.
            guard let times = translate(times: parts[0]) else { return nil }
            return times == allDay ? allDay : String(localized: "codziennie \(times)")
        case 2:
            guard let days = translate(days: parts[0]), let times = translate(times: parts[1]) else { return nil }
            if days == everyDay && times == allDay { return allDay }
            let timesText = times == allDay ? String(localized: "całą dobę") : times
            return "\(days) \(timesText)"
        default:
            return nil
        }
    }

    /// `Mo-Fr`, `Sa,Su`, `Mo-Su`, `Tu`.
    private static func translate(days: String) -> String? {
        let items = days.split(separator: ",", omittingEmptySubsequences: false)
        var labels: [String] = []
        for item in items {
            let bounds = item.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
            switch bounds.count {
            case 1:
                guard let day = weekdayIndex(bounds[0]) else { return nil }
                labels.append(weekdays[day].label)
            case 2:
                guard let start = weekdayIndex(bounds[0]), let end = weekdayIndex(bounds[1]), start < end else {
                    return nil
                }
                if start == 0 && end == weekdays.count - 1 && items.count == 1 { return everyDay }
                labels.append("\(weekdays[start].label)–\(weekdays[end].label)")
            default:
                return nil
            }
        }
        return labels.joined(separator: ", ")
    }

    private static func weekdayIndex(_ key: String) -> Int? {
        weekdays.firstIndex { $0.key == key }
    }

    /// `06:00-22:00`, `06:00-12:00,14:00-20:00`, `00:00-24:00`, `off`.
    private static func translate(times: String) -> String? {
        if times == "off" || times == "closed" { return String(localized: "nieczynne") }
        if times == "00:00-24:00" { return allDay }
        var ranges: [String] = []
        for range in times.split(separator: ",", omittingEmptySubsequences: false) {
            let bounds = range.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
            guard bounds.count == 2, let start = time(bounds[0]), let end = time(bounds[1]) else { return nil }
            ranges.append("\(start)–\(end)")
        }
        return ranges.joined(separator: ", ")
    }

    /// `06:00` → `6:00`; nil unless it is a valid `HH:MM` up to `24:00`.
    private static func time(_ value: String) -> String? {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].count == 2, parts[1].count == 2,
            parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
            let hour = Int(parts[0]), let minute = Int(parts[1]),
            minute < 60, hour < 24 || (hour == 24 && minute == 0)
        else {
            return nil
        }
        return "\(hour):\(parts[1])"
    }
}
