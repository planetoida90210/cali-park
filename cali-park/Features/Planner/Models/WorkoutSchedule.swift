import Foundation

// MARK: - WorkoutSchedule
/// How often a `WorkoutPlan` should recur. Deliberately day-granular for now:
/// time-of-day and local notifications are a separate, later concern.
///
/// - `once`: a single planned day (`nil` while the plan is still a draft).
/// - `weekly`: repeats every week on the chosen weekdays.
/// - `everyNDays`: a fixed interval measured from an anchor day.
enum WorkoutSchedule: Codable, Equatable, Hashable {
    case once(Date?)
    case weekly(Set<Weekday>)
    case everyNDays(Int, from: Date)

    /// Whether the plan repeats (a one-off does not).
    var isRecurring: Bool {
        switch self {
        case .once: false
        case .weekly, .everyNDays: true
        }
    }

    // MARK: Next occurrence
    /// The soonest scheduled day on or after `reference`, at the start of that
    /// day, or `nil` when nothing is scheduled (empty weekly set, a past
    /// one-off, a draft, or a non-positive interval). Day-granular so the
    /// result is stable regardless of the reference's time of day.
    func nextOccurrence(onOrAfter reference: Date, calendar: Calendar = .current) -> Date? {
        let referenceDay = calendar.startOfDay(for: reference)

        switch self {
        case .once(let date):
            guard let date else { return nil }
            let day = calendar.startOfDay(for: date)
            return day >= referenceDay ? day : nil

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
            let anchorDay = calendar.startOfDay(for: anchor)
            guard anchorDay < referenceDay else { return anchorDay }

            let elapsed = calendar.dateComponents([.day], from: anchorDay, to: referenceDay).day ?? 0
            let remainder = elapsed % interval
            let advance = remainder == 0 ? elapsed : elapsed + (interval - remainder)
            return calendar.date(byAdding: .day, value: advance, to: anchorDay)
        }
    }
}
