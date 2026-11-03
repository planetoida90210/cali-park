import Foundation

// MARK: - PlanAgenda
/// Pure answers to "which plan is next, and is today's plan done?", shared by
/// the Home hero and the "Następny trening" module so they never disagree.
///
/// A plan counts as done for a day when any workout log entry on that calendar
/// day carries its `planID` (a quick workout started from the plan stamps it).
/// Day boundaries come from the injected calendar, so an entry at 23:59 belongs
/// to that day and one at 00:01 to the next.
enum PlanAgenda {
    // MARK: Occurrence
    /// An active plan paired with the day it comes up (start of that day).
    struct Occurrence: Equatable {
        let plan: WorkoutPlan
        let date: Date
    }

    // MARK: Today
    /// The plans due on one day, split by whether they are done.
    struct Day: Equatable {
        /// Every active plan scheduled for the day, oldest plan first.
        let due: [WorkoutPlan]
        /// The due plans with no entry carrying their `planID` that day, in
        /// the same order. The first one is what Home offers to start.
        let undone: [WorkoutPlan]

        /// Plans were due and every one of them is done.
        var isAllDone: Bool { !due.isEmpty && undone.isEmpty }
    }

    // MARK: Queries

    /// Whether any entry on `day`'s calendar day carries `plan.id`.
    static func isDone(_ plan: WorkoutPlan,
                       on day: Date,
                       entries: [WorkoutLogEntry],
                       calendar: Calendar = .current) -> Bool {
        entries.contains { $0.planID == plan.id && calendar.isDate($0.date, inSameDayAs: day) }
    }

    /// The plans due on `today`, split into done and not done.
    static func day(_ today: Date = .now,
                    plans: [WorkoutPlan],
                    entries: [WorkoutLogEntry],
                    calendar: Calendar = .current) -> Day {
        let startOfToday = calendar.startOfDay(for: today)
        let due = plans
            .filter { $0.nextOccurrence(onOrAfter: startOfToday, calendar: calendar) == startOfToday }
            .sorted(by: olderFirst)
        let entriesToday = entries.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let undone = due.filter { plan in !entriesToday.contains { $0.planID == plan.id } }
        return Day(due: due, undone: undone)
    }

    /// The soonest occurrence that still needs doing: a plan due today counts
    /// only while it is not done, otherwise its next scheduled day is used.
    /// Ties on the same day go to the older plan, for a stable result.
    static func nextUndone(plans: [WorkoutPlan],
                           entries: [WorkoutLogEntry],
                           calendar: Calendar = .current,
                           today: Date = .now) -> Occurrence? {
        plans
            .compactMap { plan in
                nextUndoneDate(of: plan, entries: entries, calendar: calendar, today: today)
                    .map { Occurrence(plan: plan, date: $0) }
            }
            .min { $0.date != $1.date ? $0.date < $1.date : olderFirst($0.plan, $1.plan) }
    }

    /// The plan's next scheduled day, skipping today when it is already done.
    static func nextUndoneDate(of plan: WorkoutPlan,
                               entries: [WorkoutLogEntry],
                               calendar: Calendar = .current,
                               today: Date = .now) -> Date? {
        let startOfToday = calendar.startOfDay(for: today)
        guard let next = plan.nextOccurrence(onOrAfter: startOfToday, calendar: calendar) else { return nil }
        guard next == startOfToday, isDone(plan, on: today, entries: entries, calendar: calendar) else { return next }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return nil }
        return plan.nextOccurrence(onOrAfter: tomorrow, calendar: calendar)
    }

    // MARK: Helpers

    private static func olderFirst(_ lhs: WorkoutPlan, _ rhs: WorkoutPlan) -> Bool {
        lhs.createdAt != rhs.createdAt ? lhs.createdAt < rhs.createdAt : lhs.id.uuidString < rhs.id.uuidString
    }
}
