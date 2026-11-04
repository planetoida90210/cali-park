import Foundation

// MARK: - TestCalendar
/// The calendars every date test runs on, so no result depends on the
/// machine's time zone, locale or first weekday.
enum TestCalendar {
    /// Gregorian, UTC, weeks starting on Sunday. UTC has no clock change, so a
    /// day is always 86 400 s and `TestDate.epochDay(_:)` lands on midnight.
    static let utc: Calendar = gregorian(in: "UTC")

    /// Gregorian in Europe/Warsaw, weeks starting on Sunday. In 2026 the clocks
    /// go forward on 29 March (a 23-hour day) and back on 25 October (25 hours).
    static let warsaw: Calendar = gregorian(in: "Europe/Warsaw")

    /// Gregorian in `timeZoneID` with an explicit first weekday (1 = Sunday,
    /// 2 = Monday).
    static func gregorian(in timeZoneID: String, firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }
}

// MARK: - TestDate
/// Fixed whole-second reference dates. File stores encode dates as ISO 8601
/// with whole seconds, so these roundtrip exactly.
enum TestDate {
    /// Midnight UTC `n` days after 1970-01-01, which was a Thursday, plus
    /// `hour` hours. `epochDay(0)` is Thursday, `epochDay(2)` Saturday.
    static func epochDay(_ n: Int, hour: Int = 0) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400 + Double(hour) * 3_600)
    }

    /// A wall-clock time in `calendar` (UTC by default).
    static func at(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0,
        in calendar: Calendar = TestCalendar.utc
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year, month: month, day: day,
                hour: hour, minute: minute, second: second))!
    }

    /// 2026-11-04T12:00:00Z, a Wednesday: "today" for tests that only need
    /// some fixed present.
    static let reference = Date(timeIntervalSince1970: 1_793_793_600)
}
