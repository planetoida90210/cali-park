import Foundation

// MARK: - WorkoutSchedule
/// How often a `WorkoutPlan` should recur. Deliberately day-granular for now:
/// time-of-day and local notifications are a separate, later concern.
///
/// - `once`: a single planned day (`nil` while the plan is still a draft).
/// - `weekly`: repeats every week on the chosen weekdays.
/// - `everyNDays`: a fixed interval measured from an anchor day.
///
/// Days are `CalendarDay`s, not instants, so they don't move when the time
/// zone changes. Plans saved before that stored instants; `CalendarDay`
/// still decodes them.
enum WorkoutSchedule: Codable, Equatable, Hashable {
    case once(CalendarDay?)
    case weekly(Set<Weekday>)
    case everyNDays(Int, from: CalendarDay)

    /// Whether the plan repeats (a one-off does not).
    var isRecurring: Bool {
        switch self {
        case .once: false
        case .weekly, .everyNDays: true
        }
    }

    /// A one-off plan whose day is before `reference`'s day: it will never
    /// come up again. Other schedules never expire.
    func isExpired(asOf reference: Date, calendar: Calendar = .current) -> Bool {
        guard case .once(let day?) = self else { return false }
        return day.startDate(in: calendar) < calendar.startOfDay(for: reference)
    }

    // MARK: Next occurrence
    /// The soonest scheduled day on or after `reference`, at the start of that
    /// day, or `nil` when nothing is scheduled (empty weekly set, a past
    /// one-off, a draft, or a non-positive interval). Day-granular so the
    /// result is stable regardless of the reference's time of day.
    func nextOccurrence(onOrAfter reference: Date, calendar: Calendar = .current) -> Date? {
        let referenceDay = calendar.startOfDay(for: reference)

        switch self {
        case .once(let day):
            guard let day else { return nil }
            let date = day.startDate(in: calendar)
            return date >= referenceDay ? date : nil

        case .weekly(let days):
            guard !days.isEmpty else { return nil }
            for offset in 0..<7 {
                guard let candidate = calendar.date(byAdding: .day, value: offset, to: referenceDay),
                      let weekday = Weekday(rawValue: calendar.component(.weekday, from: candidate)),
                      days.contains(weekday)
                else { continue }
                return candidate
            }
            return nil

        case .everyNDays(let interval, let anchor):
            guard interval > 0 else { return nil }
            let anchorDay = anchor.startDate(in: calendar)
            guard anchorDay < referenceDay else { return anchorDay }

            let elapsed = calendar.dateComponents([.day], from: anchorDay, to: referenceDay).day ?? 0
            let remainder = elapsed % interval
            let advance = remainder == 0 ? elapsed : elapsed + (interval - remainder)
            return calendar.date(byAdding: .day, value: advance, to: anchorDay)
        }
    }
}
