import Foundation

// MARK: - WorkoutReminderPlanner
/// Pure translation from saved plans to the local reminders that should be
/// pending. No side effects and no `UserNotifications` dependency, so the
/// mapping is fully unit-testable; the concrete scheduler just registers the
/// results.
enum WorkoutReminderPlanner {
    /// iOS keeps at most 64 pending local notifications per app and silently
    /// drops the rest, so the planner never asks for more.
    static let pendingLimit = 64

    /// Reminders for every active plan that has a `reminderTime`, soonest
    /// first and capped at `limit`, so the reminders that survive the cap are
    /// the ones about to fire.
    ///
    /// - `weekly`: one repeating reminder per chosen weekday.
    /// - `once`: a single reminder on that day, only when still in the future.
    /// - `everyNDays`: one dated reminder per upcoming occurrence (a calendar
    ///   trigger can't repeat every N days). The cap bounds how far ahead they
    ///   go; every reschedule (on launch, on foreground, after an edit) tops
    ///   them up again.
    static func requests(for plans: [WorkoutPlan],
                         calendar: Calendar = .current,
                         asOf reference: Date = .now,
                         limit: Int = pendingLimit) -> [WorkoutReminderRequest] {
        let candidates = plans.flatMap { candidates(for: $0, calendar: calendar, asOf: reference, limit: limit) }
        return candidates
            .sorted { $0.fireDate != $1.fireDate ? $0.fireDate < $1.fireDate : $0.request.id < $1.request.id }
            .prefix(max(0, limit))
            .map(\.request)
    }

    static func requests(for plan: WorkoutPlan,
                         calendar: Calendar = .current,
                         asOf reference: Date = .now,
                         limit: Int = pendingLimit) -> [WorkoutReminderRequest] {
        requests(for: [plan], calendar: calendar, asOf: reference, limit: limit)
    }

    // MARK: Candidates

    /// A request paired with when it fires next, for ordering under the cap.
    private struct Candidate {
        let request: WorkoutReminderRequest
        let fireDate: Date
    }

    private static func candidates(for plan: WorkoutPlan,
                                   calendar: Calendar,
                                   asOf reference: Date,
                                   limit: Int) -> [Candidate] {
        guard plan.isActive,
              let time = plan.reminderTime,
              let hour = time.hour,
              let minute = time.minute
        else { return [] }

        let title = plan.name.isEmpty ? "Trening" : plan.name
        let body = "Czas na trening. \(PolishPlural.exercises(plan.exerciseCount))."
        func request(id: String, components: DateComponents, repeats: Bool) -> WorkoutReminderRequest {
            WorkoutReminderRequest(id: "plan-\(plan.id.uuidString)-\(id)",
                                   planID: plan.id,
                                   title: title,
                                   body: body,
                                   dateComponents: components,
                                   repeats: repeats)
        }

        switch plan.schedule {
        case .weekly(let days):
            return days.sorted { $0.rawValue < $1.rawValue }.compactMap { weekday in
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                components.weekday = weekday.rawValue
                guard let fireDate = calendar.nextDate(after: reference,
                                                       matching: components,
                                                       matchingPolicy: .nextTime)
                else { return nil }
                return Candidate(request: request(id: "wd\(weekday.rawValue)", components: components, repeats: true),
                                 fireDate: fireDate)
            }

        case .once:
            guard let day = nextFireDay(for: plan.schedule, onOrAfter: reference, hour: hour, minute: minute, calendar: calendar),
                  let fire = fireDate(on: day, hour: hour, minute: minute, calendar: calendar)
            else { return [] }
            return [Candidate(request: request(id: "once", components: fire.components, repeats: false),
                              fireDate: fire.date)]

        case .everyNDays:
            var result: [Candidate] = []
            var from = reference
            while result.count < limit,
                  let day = nextFireDay(for: plan.schedule, onOrAfter: from, hour: hour, minute: minute, calendar: calendar),
                  let fire = fireDate(on: day, hour: hour, minute: minute, calendar: calendar),
                  let dayAfter = calendar.date(byAdding: .day, value: 1, to: day) {
                result.append(Candidate(request: request(id: dayKey(fire.components), components: fire.components, repeats: false),
                                        fireDate: fire.date))
                from = dayAfter
            }
            return result
        }
    }

    // MARK: Helpers

    /// The next scheduled day on or after `reference` whose reminder time is
    /// still ahead of `reference`. When that day's time already passed,
    /// advances to the following scheduled day (`nil` for a past one-off).
    private static func nextFireDay(for schedule: WorkoutSchedule,
                                    onOrAfter reference: Date,
                                    hour: Int,
                                    minute: Int,
                                    calendar: Calendar) -> Date? {
        guard let day = schedule.nextOccurrence(onOrAfter: reference, calendar: calendar),
              let fire = fireDate(on: day, hour: hour, minute: minute, calendar: calendar)
        else { return nil }

        if fire.date > reference { return day }

        guard let dayAfter = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
        return schedule.nextOccurrence(onOrAfter: dayAfter, calendar: calendar)
    }

    /// The calendar components and instant of `hour:minute` on `day`.
    private static func fireDate(on day: Date,
                                 hour: Int,
                                 minute: Int,
                                 calendar: Calendar) -> (components: DateComponents, date: Date)? {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        guard let date = calendar.date(from: components) else { return nil }
        return (components, date)
    }

    /// `on-2026-11-04`, so each dated interval reminder has a stable id.
    private static func dayKey(_ components: DateComponents) -> String {
        String(format: "on-%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
