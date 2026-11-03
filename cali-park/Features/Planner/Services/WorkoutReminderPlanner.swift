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

    /// Reminders for every active plan that has a `reminderTime`: one dated,
    /// non-repeating reminder per upcoming occurrence, soonest first and
    /// capped at `limit`.
    ///
    /// Every schedule type is dated (a repeating trigger would also fire on a
    /// day the plan is already done). An occurrence on a day where
    /// `PlanAgenda` counts the plan as done, given `entries`, gets no reminder.
    ///
    /// Soonest first also shares the cap fairly: every plan is covered up to
    /// the same date, so a daily plan can't push out a weekly one that fires
    /// earlier. The cap bounds how far ahead reminders go; every sync (launch,
    /// foreground, background refresh, a plan or log change) tops them up.
    static func requests(for plans: [WorkoutPlan],
                         entries: [WorkoutLogEntry] = [],
                         calendar: Calendar = .current,
                         asOf reference: Date = .now,
                         limit: Int = pendingLimit) -> [WorkoutReminderRequest] {
        let done = PlanAgenda.DoneDays(entries: entries, calendar: calendar)
        let all = plans.flatMap {
            Self.candidates(for: $0, skipping: done, calendar: calendar, asOf: reference, limit: limit)
        }
        return all
            .sorted { $0.fireDate != $1.fireDate ? $0.fireDate < $1.fireDate : $0.request.id < $1.request.id }
            .prefix(max(0, limit))
            .map(\.request)
    }

    static func requests(for plan: WorkoutPlan,
                         entries: [WorkoutLogEntry] = [],
                         calendar: Calendar = .current,
                         asOf reference: Date = .now,
                         limit: Int = pendingLimit) -> [WorkoutReminderRequest] {
        requests(for: [plan], entries: entries, calendar: calendar, asOf: reference, limit: limit)
    }

    // MARK: Candidates

    /// A request paired with when it fires, for ordering under the cap.
    private struct Candidate {
        let request: WorkoutReminderRequest
        let fireDate: Date
    }

    /// Up to `limit` upcoming reminders for one plan, skipping done days.
    /// No plan needs more than `limit`, since the merged list is cut there.
    private static func candidates(for plan: WorkoutPlan,
                                   skipping done: PlanAgenda.DoneDays,
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

        var result: [Candidate] = []
        var from = reference
        while result.count < limit,
              let day = nextFireDay(for: plan.schedule, onOrAfter: from, hour: hour, minute: minute, calendar: calendar),
              let fire = fireDate(on: day, hour: hour, minute: minute, calendar: calendar),
              let dayAfter = calendar.date(byAdding: .day, value: 1, to: day) {
            if !done.contains(plan.id, on: day) {
                let request = WorkoutReminderRequest(id: "plan-\(plan.id.uuidString)-\(dayKey(fire.components))",
                                                     planID: plan.id,
                                                     title: title,
                                                     body: body,
                                                     dateComponents: fire.components)
                result.append(Candidate(request: request, fireDate: fire.date))
            }
            from = dayAfter
        }
        return result
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

    /// `on-2026-11-04`, so each dated reminder has a stable id.
    private static func dayKey(_ components: DateComponents) -> String {
        func padded(_ value: Int?, to width: Int) -> String {
            let digits = String(value ?? 0)
            return String(repeating: "0", count: max(0, width - digits.count)) + digits
        }
        return "on-\(padded(components.year, to: 4))-\(padded(components.month, to: 2))-\(padded(components.day, to: 2))"
    }
}
