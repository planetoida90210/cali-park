import Foundation

// MARK: - WeeklyGoalEvaluator
/// Pure weekly-goal math: a week's targets and progress, its verdict, and the
/// week streak. Everything is recomputed from the workout log, the plans and
/// the `WeeklyGoalHistory`, on the injected calendar and reference date.
///
/// Rules (ticket 027, modelled on Apple Watch activity rings):
/// - A week runs Monday 00:00 to the next Monday 00:00, whatever the locale's
///   first weekday.
/// - The current week uses the latest goals; a closed week uses the version in
///   force when it ended.
/// - The first, partial week after the goal was first set is a warm-up week:
///   met counts toward the streak, not met is neutral. A goal first set on a
///   Monday starts with a full week.
/// - A week a pause touches is neutral unless the goal was met anyway.
/// - The current week never breaks the streak while it is still running.
nonisolated enum WeeklyGoalEvaluator {
    // MARK: Weeks

    /// The Monday–Sunday week containing `date`: Monday 00:00 up to the next
    /// Monday 00:00 (exclusive), on `calendar`'s time zone.
    static func week(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        let day = calendar.startOfDay(for: date)
        // Calendar weekdays: Sunday = 1 … Saturday = 7. Days since Monday:
        let sinceMonday = (calendar.component(.weekday, from: day) + 5) % 7
        let start = calendar.date(byAdding: .day, value: -sinceMonday, to: day) ?? day
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(7 * 86_400)
        return DateInterval(start: start, end: end)
    }

    /// The week before `week`.
    static func week(before week: DateInterval, calendar: Calendar = .current) -> DateInterval {
        let previousDay = calendar.date(byAdding: .day, value: -1, to: week.start) ?? week.start.addingTimeInterval(-86_400)
        return self.week(containing: previousDay, calendar: calendar)
    }

    // MARK: Progress

    /// One goal's target and progress in `week`. Only entries inside the week
    /// count; `plans` matter only for "all scheduled".
    static func progress(of goal: WeeklyGoal,
                         in week: DateInterval,
                         entries: [WorkoutLogEntry],
                         plans: [WorkoutPlan],
                         calendar: Calendar = .current) -> WeeklyGoalProgress {
        let inWeek = entries.filter { contains(week, $0.date) }
        switch goal.metric {
        case let .trainingDays(days):
            let trained = Set(inWeek.map { calendar.startOfDay(for: $0.date) })
            return WeeklyGoalProgress(goal: goal, target: days, value: trained.count)

        case let .plannedWorkouts(.count(workouts)):
            return WeeklyGoalProgress(goal: goal, target: workouts, value: planWorkouts(in: inWeek, calendar: calendar).count)

        case .plannedWorkouts(.allScheduled):
            return allScheduledProgress(goal: goal, week: week, entries: inWeek, plans: plans, calendar: calendar)

        case let .exerciseVolume(exerciseID, measurement, amount):
            let matching = inWeek.filter { $0.exerciseID == exerciseID }
            let value = matching.reduce(0) { total, entry in
                total + (measurement == .seconds ? entry.totalSeconds : entry.totalReps)
            }
            return WeeklyGoalProgress(goal: goal, target: amount, value: value)
        }
    }

    // MARK: Week verdict

    /// `week` judged against the goals in force for it, or `nil` when the week
    /// ends before the first goal version took effect. The current week uses
    /// the latest version that has taken effect.
    static func evaluate(week: DateInterval,
                         versions: [WeeklyGoalVersion],
                         pauses: [WeeklyGoalPause],
                         entries: [WorkoutLogEntry],
                         plans: [WorkoutPlan],
                         calendar: Calendar = .current,
                         asOf: Date = .now) -> WeeklyGoalWeek? {
        guard let first = versions.first,
              let version = versions.last(where: { $0.effectiveFrom < week.end && $0.effectiveFrom <= asOf })
        else { return nil }
        return judge(week: week, version: version, firstSetAt: first.effectiveFrom, pauses: pauses,
                     entries: entries, plans: plans, calendar: calendar, asOf: asOf)
    }

    /// The verdict for `week` under `version`.
    private static func judge(week: DateInterval,
                              version: WeeklyGoalVersion,
                              firstSetAt: Date,
                              pauses: [WeeklyGoalPause],
                              entries: [WorkoutLogEntry],
                              plans: [WorkoutPlan],
                              calendar: Calendar,
                              asOf: Date) -> WeeklyGoalWeek {
        let goals = version.goals.map {
            progress(of: $0, in: week, entries: entries, plans: plans, calendar: calendar)
        }
        let isPaused = pauses.contains { $0.overlaps(week) }
        let isWarmUp = contains(week, firstSetAt) && calendar.startOfDay(for: firstSetAt) != week.start

        let primary = goals[0]
        let status: WeeklyGoalWeekStatus =
            if primary.isMet { .met }
            else if primary.target == 0 { .nothingScheduled }
            else if isPaused { .paused }
            else if isWarmUp { .warmUp }
            else if asOf < week.end { .inProgress }
            else { .missed }

        return WeeklyGoalWeek(interval: week, goals: goals, status: status, isPaused: isPaused, isWarmUp: isWarmUp)
    }

    // MARK: Streak

    /// Weeks in a row with the primary goal met, counted back from the week of
    /// `asOf`. Neutral weeks (running, paused, warm-up, nothing scheduled) are
    /// skipped; a missed week or the start of the history ends the count.
    static func streak(versions: [WeeklyGoalVersion],
                       pauses: [WeeklyGoalPause],
                       entries: [WorkoutLogEntry],
                       plans: [WorkoutPlan],
                       calendar: Calendar = .current,
                       asOf: Date = .now) -> Int {
        guard let first = versions.first else { return 0 }
        let byWeek = Dictionary(grouping: entries) { week(containing: $0.date, calendar: calendar).start }

        var count = 0
        var current = week(containing: asOf, calendar: calendar)
        while current.end > first.effectiveFrom {
            guard let judged = evaluate(
                week: current, versions: versions, pauses: pauses,
                entries: byWeek[current.start] ?? [], plans: plans,
                calendar: calendar, asOf: asOf
            ) else { break }
            switch judged.status {
            case .met: count += 1
            case .missed: return count
            case .inProgress, .paused, .warmUp, .nothingScheduled: break
            }
            current = week(before: current, calendar: calendar)
        }
        return count
    }

    // MARK: Snapshot

    /// Where the implicit default goal begins: the first logged workout, or
    /// `asOf` for an empty journal.
    static func implicitStart(entries: [WorkoutLogEntry], asOf: Date) -> Date {
        min(entries.map(\.date).min() ?? asOf, asOf)
    }

    /// The current week, the streak, the active pause and the celebrations
    /// still to show, for Home.
    static func snapshot(history: WeeklyGoalHistory,
                         entries: [WorkoutLogEntry],
                         plans: [WorkoutPlan],
                         calendar: Calendar = .current,
                         asOf: Date = .now) -> WeeklyGoalSnapshot {
        let versions = history.effectiveVersions(implicitStart: implicitStart(entries: entries, asOf: asOf))
        let currentWeek = week(containing: asOf, calendar: calendar)
        // The latest version that has taken effect; the first one if the clock
        // reads earlier than every version (e.g. after a time zone change).
        let version = versions.last { $0.effectiveFrom <= asOf } ?? versions[0]
        let judged = judge(
            week: currentWeek, version: version, firstSetAt: versions[0].effectiveFrom,
            pauses: history.pauses, entries: entries, plans: plans, calendar: calendar, asOf: asOf
        )
        let pending = judged.goals.filter {
            $0.isMet && !history.hasCelebrated(goalID: $0.goal.id, weekStart: currentWeek.start)
        }
        return WeeklyGoalSnapshot(
            week: judged,
            streak: streak(versions: versions, pauses: history.pauses, entries: entries,
                           plans: plans, calendar: calendar, asOf: asOf),
            activePause: history.activePause(at: asOf),
            pendingCelebrations: pending,
            isDefault: history.versions.isEmpty
        )
    }

    // MARK: Helpers

    /// Half-open containment: the week's end belongs to the next week.
    private static func contains(_ interval: DateInterval, _ date: Date) -> Bool {
        interval.start <= date && date < interval.end
    }

    /// Distinct (plan, day) pairs among entries logged from a plan: one plan
    /// workout per plan per day, however many exercises it logged.
    private static func planWorkouts(in entries: [WorkoutLogEntry], calendar: Calendar) -> Set<PlanDay> {
        Set(entries.compactMap { entry in
            entry.planID.map { PlanDay(planID: $0, day: calendar.startOfDay(for: entry.date)) }
        })
    }

    /// "All scheduled": the target is every plan occurrence in the week. A plan
    /// done on another day of the same week still counts, up to the number of
    /// times it was scheduled, so moving a session within the week is fine.
    private static func allScheduledProgress(goal: WeeklyGoal,
                                             week: DateInterval,
                                             entries: [WorkoutLogEntry],
                                             plans: [WorkoutPlan],
                                             calendar: Calendar) -> WeeklyGoalProgress {
        let scheduled = Dictionary(
            grouping: PlanAgenda.occurrences(of: plans, in: week, calendar: calendar),
            by: \.plan.id
        ).mapValues(\.count)
        let done = Dictionary(grouping: planWorkouts(in: entries, calendar: calendar), by: \.planID).mapValues(\.count)
        let value = scheduled.reduce(0) { total, pair in total + min(pair.value, done[pair.key] ?? 0) }
        return WeeklyGoalProgress(goal: goal, target: scheduled.values.reduce(0, +), value: value)
    }

    private struct PlanDay: Hashable {
        let planID: UUID
        let day: Date
    }
}
