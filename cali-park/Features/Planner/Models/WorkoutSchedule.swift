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
///
/// The on-disk shape is written by hand (below), frozen to what the
/// synthesized `Codable` produced, so renaming a case or a label can't
/// silently change the file format (audit C-4).
nonisolated enum WorkoutSchedule: Codable, Equatable, Hashable {
    case once(CalendarDay?)
    case weekly(Set<Weekday>)
    case everyNDays(Int, from: CalendarDay)

    // MARK: Codable
    // {"once":{"_0":"2026-11-04"}}, {"once":{}} for a draft,
    // {"weekly":{"_0":[2,5]}} and {"everyNDays":{"_0":3,"from":"2026-11-04"}}.
    private enum Kind: String, CodingKey {
        case once, weekly, everyNDays
    }

    private enum PayloadKey: String, CodingKey {
        case value = "_0"
        case from
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Kind.self)
        guard container.allKeys.count == 1, let kind = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected exactly one schedule kind, found \(container.allKeys.map(\.stringValue))"
                ))
        }
        let payload = try container.nestedContainer(keyedBy: PayloadKey.self, forKey: kind)
        switch kind {
        case .once:
            self = .once(try payload.decodeIfPresent(CalendarDay.self, forKey: .value))
        case .weekly:
            self = .weekly(try payload.decode(Set<Weekday>.self, forKey: .value))
        case .everyNDays:
            self = .everyNDays(
                try payload.decode(Int.self, forKey: .value),
                from: try payload.decode(CalendarDay.self, forKey: .from))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Kind.self)
        switch self {
        case .once(let day):
            var payload = container.nestedContainer(keyedBy: PayloadKey.self, forKey: .once)
            try payload.encodeIfPresent(day, forKey: .value)
        case .weekly(let days):
            var payload = container.nestedContainer(keyedBy: PayloadKey.self, forKey: .weekly)
            // Sorted, so the same plan always writes the same bytes.
            try payload.encode(days.map(\.rawValue).sorted(), forKey: .value)
        case .everyNDays(let interval, let anchor):
            var payload = container.nestedContainer(keyedBy: PayloadKey.self, forKey: .everyNDays)
            try payload.encode(interval, forKey: .value)
            try payload.encode(anchor, forKey: .from)
        }
    }

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
