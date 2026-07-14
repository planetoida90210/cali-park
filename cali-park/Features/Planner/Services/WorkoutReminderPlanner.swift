import Foundation

// MARK: - WorkoutReminderPlanner
/// Pure translation from saved plans to the local reminders that should be
/// pending. No side effects and no `UserNotifications` dependency, so the
/// mapping is fully unit-testable; the concrete scheduler just registers the
/// results.
enum WorkoutReminderPlanner {
    /// Reminders for every active plan that has a `reminderTime`.
    ///
    /// - `weekly`: one repeating reminder per chosen weekday.
    /// - `once`: a single reminder on that day, only when still in the future.
    /// - `everyNDays`: a single reminder on the next occurrence (repeating
    ///   intervals can't be expressed by a calendar trigger, so this is
    ///   re-planned when the app next reschedules).
    static func requests(for plans: [WorkoutPlan],
                         calendar: Calendar = .current,
                         asOf reference: Date = .now) -> [WorkoutReminderRequest] {
        plans.flatMap { requests(for: $0, calendar: calendar, asOf: reference) }
    }

    static func requests(for plan: WorkoutPlan,
                         calendar: Calendar = .current,
                         asOf reference: Date = .now) -> [WorkoutReminderRequest] {
        guard plan.isActive,
              let time = plan.reminderTime,
              let hour = time.hour,
              let minute = time.minute
        else { return [] }

        let title = plan.name.isEmpty ? "Trening" : plan.name
        let body = "Czas na trening · \(PolishPlural.exercises(plan.exerciseCount))"

        switch plan.schedule {
        case .weekly(let days):
            return days.sorted { $0.rawValue < $1.rawValue }.map { weekday in
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                components.weekday = weekday.rawValue
                return WorkoutReminderRequest(
                    id: "plan-\(plan.id.uuidString)-wd\(weekday.rawValue)",
                    planID: plan.id,
                    title: title,
                    body: body,
                    dateComponents: components,
                    repeats: true
                )
            }

        case .once, .everyNDays:
            guard let fireDay = nextFireDay(for: plan.schedule,
                                            hour: hour,
                                            minute: minute,
                                            calendar: calendar,
                                            asOf: reference) else { return [] }
            let suffix = plan.schedule.isRecurring ? "interval" : "once"
            return [WorkoutReminderRequest(
                id: "plan-\(plan.id.uuidString)-\(suffix)",
                planID: plan.id,
                title: title,
                body: body,
                dateComponents: dateComponents(for: fireDay, hour: hour, minute: minute, calendar: calendar),
                repeats: false
            )]
        }
    }

    // MARK: Helpers

    /// The next day whose reminder time is still in the future. For `once`
    /// returns `nil` once the day has passed; for `everyNDays` advances to the
    /// following interval when today's time already elapsed.
    private static func nextFireDay(for schedule: WorkoutSchedule,
                                    hour: Int,
                                    minute: Int,
                                    calendar: Calendar,
                                    asOf reference: Date) -> Date? {
        guard let day = schedule.nextOccurrence(onOrAfter: reference, calendar: calendar) else { return nil }
        let fireComponents = dateComponents(for: day, hour: hour, minute: minute, calendar: calendar)
        guard let fireDate = calendar.date(from: fireComponents) else { return nil }

        if fireDate > reference { return day }

        // Today's reminder time already passed: skip to the next scheduled day.
        guard let dayAfter = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
        return schedule.nextOccurrence(onOrAfter: dayAfter, calendar: calendar)
    }

    private static func dateComponents(for day: Date,
                                       hour: Int,
                                       minute: Int,
                                       calendar: Calendar) -> DateComponents {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return components
    }
}
