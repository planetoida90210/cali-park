import Foundation

// MARK: - Weekday
/// A day of the week whose `rawValue` matches `Calendar`'s `.weekday` component
/// (Sunday = 1 … Saturday = 7 in the Gregorian calendar). Storing the raw
/// `Calendar` value keeps schedule math trivial: `Weekday(rawValue:)` maps a
/// date's weekday straight back to a case.
enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    /// Full Polish name, e.g. "Poniedziałek". English raw values would be
    /// safer for localization, but `rawValue` must equal the `Calendar` index,
    /// so the Polish text lives here (mirrors `MuscleGroup.displayName`).
    var displayName: String {
        switch self {
        case .monday: "Poniedziałek"
        case .tuesday: "Wtorek"
        case .wednesday: "Środa"
        case .thursday: "Czwartek"
        case .friday: "Piątek"
        case .saturday: "Sobota"
        case .sunday: "Niedziela"
        }
    }

    /// Compact label for chips and summaries, e.g. "Pon".
    var shortName: String {
        switch self {
        case .monday: "Pon"
        case .tuesday: "Wt"
        case .wednesday: "Śr"
        case .thursday: "Czw"
        case .friday: "Pt"
        case .saturday: "Sob"
        case .sunday: "Ndz"
        }
    }

    /// Weekdays ordered by the calendar's first weekday, so a picker follows
    /// the user's locale (Monday-first in Poland, Sunday-first in the US).
    static func ordered(for calendar: Calendar = .current) -> [Weekday] {
        let start = calendar.firstWeekday
        return (0..<7).map { offset in
            let raw = (start - 1 + offset) % 7 + 1
            return Weekday(rawValue: raw) ?? .monday
        }
    }
}
