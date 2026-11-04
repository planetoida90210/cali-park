import Foundation

// MARK: - CalendarDay
/// A day on the calendar ("2026-11-10") with no time and no time zone, for
/// schedule values that mean a day, not an instant. A one-off plan for
/// 10 November stays on 10 November after the athlete changes time zone,
/// because the day is resolved in whatever calendar reads it.
///
/// Year, month and day are Gregorian whatever calendar the device uses; the
/// conversions below take the day boundaries from the given calendar's time
/// zone, which are the same in every calendar system.
///
/// Encoded as a `"yyyy-MM-dd"` string. Decoding also reads the format that
/// workout plans used before (an ISO 8601 instant at the local midnight of
/// the zone the plan was saved in): the instant becomes the day it falls on
/// in the calendar under `CalendarDay.legacyCalendarKey` in the decoder's
/// `userInfo`, or `Calendar.current` without one. That is the day the app
/// showed for the plan before the change.
struct CalendarDay: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    /// `nil` for a day that doesn't exist (31 June).
    init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(year: year, month: month, day: day)
        guard components.isValidDate(in: Self.gregorianUTC) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar` (its time zone decides).
    init(_ date: Date, in calendar: Calendar) {
        let components = Self.gregorian(in: calendar.timeZone).dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 1970
        month = components.month ?? 1
        day = components.day ?? 1
    }

    /// The start of this day in `calendar`.
    func startDate(in calendar: Calendar) -> Date {
        // Noon always exists; midnight may not on a day when DST starts at 00:00.
        let noon = DateComponents(year: year, month: month, day: day, hour: 12)
        let date = Self.gregorian(in: calendar.timeZone).date(from: noon) ?? .distantPast
        return calendar.startOfDay(for: date)
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    // MARK: Calendars
    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static let gregorianUTC = gregorian(in: .gmt)
}

// MARK: - Codable
extension CalendarDay: Codable {
    /// `userInfo` key for the `Calendar` that turns a legacy instant into a day.
    static let legacyCalendarKey = CodingUserInfoKey(rawValue: "calipark.legacyDayCalendar")!

    /// `"2026-11-10"`.
    var key: String {
        func padded(_ value: Int, to width: Int) -> String {
            let digits = String(value)
            return String(repeating: "0", count: max(0, width - digits.count)) + digits
        }
        return "\(padded(year, to: 4))-\(padded(month, to: 2))-\(padded(day, to: 2))"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        if let day = Self(key: text) {
            self = day
        } else if let instant = try? Date(text, strategy: .iso8601) {
            let calendar = decoder.userInfo[Self.legacyCalendarKey] as? Calendar ?? .current
            self.init(instant, in: calendar)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Expected a yyyy-MM-dd day, got \(text)"
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    /// Parses exactly `yyyy-MM-dd`.
    private init?(key: String) {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }
}
