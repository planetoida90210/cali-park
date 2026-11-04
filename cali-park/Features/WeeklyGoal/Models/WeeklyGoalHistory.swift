import Foundation

// MARK: - WeeklyGoalHistory
/// Everything the weekly goal persists: the goal versions, the pauses and which
/// met goals have already been celebrated. Progress is never stored; it is
/// always recomputed from the workout log by `WeeklyGoalEvaluator`.
///
/// No versions means nothing was saved yet: the implicit default ("3 training
/// days") applies from the athlete's first logged workout. The first save
/// writes that default version down before the new one, so the streak earned
/// under the default survives the edit.
nonisolated struct WeeklyGoalHistory: Codable, Equatable, Sendable {
    /// Oldest first. Empty until the athlete first changes the goals.
    var versions: [WeeklyGoalVersion]
    /// Oldest first. At most one is active at a time.
    var pauses: [WeeklyGoalPause]
    /// Goals whose "met" celebration was shown, per week.
    var celebrated: Set<WeeklyGoalCelebration>
    /// Oldest first, at most one per week: the plans as they were scheduled,
    /// so a closed week's "all scheduled" target is the plans of that week.
    /// Empty in files from before it existed; closed weeks then count with
    /// the earliest record, or today's plans while there is none.
    var planSchedules: [PlanScheduleRecord]

    init(versions: [WeeklyGoalVersion] = [],
         pauses: [WeeklyGoalPause] = [],
         celebrated: Set<WeeklyGoalCelebration> = [],
         planSchedules: [PlanScheduleRecord] = []) {
        self.versions = versions
        self.pauses = pauses
        self.celebrated = celebrated
        self.planSchedules = planSchedules
    }

    // MARK: Codable
    // `planSchedules` came later: a missing key decodes as empty, and an
    // empty list is not written, so a history without plans encodes exactly
    // as before. The envelope stays at schema version 1 (the key only adds).
    private enum CodingKeys: String, CodingKey {
        case versions, pauses, celebrated, planSchedules
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        versions = try container.decode([WeeklyGoalVersion].self, forKey: .versions)
        pauses = try container.decode([WeeklyGoalPause].self, forKey: .pauses)
        celebrated = try container.decode(Set<WeeklyGoalCelebration>.self, forKey: .celebrated)
        planSchedules = try container.decodeIfPresent([PlanScheduleRecord].self, forKey: .planSchedules) ?? []
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(versions, forKey: .versions)
        try container.encode(pauses, forKey: .pauses)
        try container.encode(celebrated, forKey: .celebrated)
        if !planSchedules.isEmpty {
            try container.encode(planSchedules, forKey: .planSchedules)
        }
    }

    static let empty = WeeklyGoalHistory()

    /// How many weeks of celebration marks to keep; older weeks can no longer
    /// celebrate, so their marks are dropped on the next mark.
    static let celebrationRetentionWeeks = 8

    // MARK: Queries

    /// The versions to evaluate: the saved ones, or the implicit default from
    /// `implicitStart` while nothing is saved.
    func effectiveVersions(implicitStart: Date) -> [WeeklyGoalVersion] {
        guard versions.isEmpty else { return versions }
        return [WeeklyGoalVersion(effectiveFrom: implicitStart, goals: WeeklyGoal.defaultGoals)]
    }

    /// The goals in force at `date`: the latest saved version, or the default.
    func currentGoals(at date: Date) -> [WeeklyGoal] {
        versions.last { $0.effectiveFrom <= date }?.goals ?? versions.first?.goals ?? WeeklyGoal.defaultGoals
    }

    /// The pause in force at `date`, if any.
    func activePause(at date: Date) -> WeeklyGoalPause? {
        pauses.last { $0.isActive(at: date) }
    }

    // MARK: Goals

    /// The history after the athlete sets `goals` at `date`. The change applies
    /// to the whole current week at once; closed weeks keep the version that
    /// was in force when they ended.
    ///
    /// - `implicitStart`: where the implicit default began (the first logged
    ///   workout). Used only on the first save, to write the default down.
    /// - A version that took effect earlier in the same week is replaced, not
    ///   stacked: no closed week can depend on it, and keeping its date keeps
    ///   the first week's warm-up anchor where it was.
    ///
    /// Returns `nil` when `goals` is not a valid set.
    func settingGoals(_ goals: [WeeklyGoal],
                      at date: Date,
                      implicitStart: Date,
                      calendar: Calendar = .current) -> WeeklyGoalHistory? {
        guard WeeklyGoal.isValidSet(goals) else { return nil }
        var history = self
        if history.versions.isEmpty {
            history.versions = [WeeklyGoalVersion(effectiveFrom: min(implicitStart, date), goals: WeeklyGoal.defaultGoals)]
        }
        let currentWeek = WeeklyGoalEvaluator.week(containing: date, calendar: calendar)
        let lastIndex = history.versions.index(before: history.versions.endIndex)
        if currentWeek.contains(history.versions[lastIndex].effectiveFrom) {
            history.versions[lastIndex].goals = goals
            // Changed back to what applied before this week: nothing to keep.
            if lastIndex > 0, history.versions[lastIndex - 1].goals == goals {
                history.versions.removeLast()
            }
        } else if history.versions[lastIndex].goals != goals {
            history.versions.append(WeeklyGoalVersion(effectiveFrom: date, goals: goals))
        }
        return history
    }

    // MARK: Plan schedules

    /// The plans to count a week's "all scheduled" target with. A week still
    /// running at `asOf` uses `currentPlans`. A closed week uses the record in
    /// force when it ended, or the earliest record for a week before every
    /// record; with no record at all, `currentPlans`.
    func plans(for week: DateInterval, currentPlans: [WorkoutPlan], asOf: Date) -> [WorkoutPlan] {
        WeeklyGoalEvaluator.plans(for: week, records: planSchedules, currentPlans: currentPlans, asOf: asOf)
    }

    /// The history with the active plans' schedules recorded at `date`, or
    /// `nil` when they match the latest record (or there are no active plans
    /// and no record yet). A record from earlier in the same week is
    /// replaced, not stacked, since no closed week can depend on it; like goal
    /// versions, there is at most one record per week.
    func recordingPlans(_ plans: [WorkoutPlan],
                        at date: Date,
                        calendar: Calendar = .current) -> WeeklyGoalHistory? {
        let scheduled = PlanScheduleRecord.scheduled(plans)
        guard let last = planSchedules.last else {
            // No plans and nothing recorded: there is nothing to keep.
            guard !scheduled.isEmpty else { return nil }
            var history = self
            history.planSchedules = [PlanScheduleRecord(effectiveFrom: date, plans: scheduled)]
            return history
        }
        guard last.plans != scheduled else { return nil }

        var history = self
        let currentWeek = WeeklyGoalEvaluator.week(containing: date, calendar: calendar)
        if currentWeek.contains(last.effectiveFrom) {
            let lastIndex = history.planSchedules.index(before: history.planSchedules.endIndex)
            history.planSchedules[lastIndex].plans = scheduled
            // Changed back to what applied before this week: nothing to keep.
            if lastIndex > 0, history.planSchedules[lastIndex - 1].plans == scheduled {
                history.planSchedules.removeLast()
            }
        } else {
            history.planSchedules.append(PlanScheduleRecord(effectiveFrom: date, plans: scheduled))
        }
        return history
    }

    // MARK: Pauses

    /// The history with a pause from the start of `date`'s day until the start
    /// of `end`'s day, clamped to 1–90 days. `nil` while a pause is active.
    func startingPause(at date: Date,
                       until end: Date,
                       calendar: Calendar = .current,
                       id: UUID = UUID()) -> WeeklyGoalHistory? {
        guard activePause(at: date) == nil else { return nil }
        let start = calendar.startOfDay(for: date)
        let requested = calendar.startOfDay(for: end)
        guard let earliest = calendar.date(byAdding: .day, value: 1, to: start),
              let latest = calendar.date(byAdding: .day, value: WeeklyGoalPause.maximumDays, to: start)
        else { return nil }
        var history = self
        history.pauses.append(WeeklyGoalPause(id: id, start: start, plannedEnd: min(max(requested, earliest), latest)))
        return history
    }

    /// The history with the active pause ended at `date`. A pause ended before
    /// it really began (same instant as its start) is removed. `nil` when no
    /// pause is active.
    func endingPause(at date: Date) -> WeeklyGoalHistory? {
        guard let index = pauses.lastIndex(where: { $0.isActive(at: date) }) else { return nil }
        var history = self
        if date <= history.pauses[index].start {
            history.pauses.remove(at: index)
        } else {
            history.pauses[index].endedAt = date
        }
        return history
    }

    // MARK: Celebrations

    func hasCelebrated(goalID: UUID, weekStart: Date) -> Bool {
        celebrated.contains(WeeklyGoalCelebration(weekStart: weekStart, goalID: goalID))
    }

    /// The history with a goal's celebration for one week marked as shown.
    /// Marks older than `celebrationRetentionWeeks` before that week are
    /// dropped, so the file does not grow forever.
    func markingCelebrated(goalID: UUID, weekStart: Date, calendar: Calendar = .current) -> WeeklyGoalHistory {
        var history = self
        history.celebrated.insert(WeeklyGoalCelebration(weekStart: weekStart, goalID: goalID))
        if let cutoff = calendar.date(byAdding: .day, value: -7 * Self.celebrationRetentionWeeks, to: weekStart) {
            history.celebrated = history.celebrated.filter { $0.weekStart >= cutoff }
        }
        return history
    }
}
