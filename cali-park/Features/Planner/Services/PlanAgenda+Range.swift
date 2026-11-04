import Foundation

// MARK: - PlanAgenda: occurrences in a range
nonisolated extension PlanAgenda {
    /// Every day in `interval` on which an active plan is scheduled, by the
    /// plans' own schedules, ordered by day and then by plan age. A plan
    /// counts only from the day it was created, so a new weekly plan does not
    /// appear in the days before it existed.
    static func occurrences(of plans: [WorkoutPlan],
                            in interval: DateInterval,
                            calendar: Calendar = .current) -> [Occurrence] {
        var result: [Occurrence] = []
        var day = calendar.startOfDay(for: interval.start)
        let ordered = plans.sorted {
            $0.createdAt != $1.createdAt ? $0.createdAt < $1.createdAt : $0.id.uuidString < $1.id.uuidString
        }
        while day < interval.end {
            for plan in ordered where calendar.startOfDay(for: plan.createdAt) <= day {
                if plan.nextOccurrence(onOrAfter: day, calendar: calendar) == day {
                    result.append(Occurrence(plan: plan, date: day))
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }
}
