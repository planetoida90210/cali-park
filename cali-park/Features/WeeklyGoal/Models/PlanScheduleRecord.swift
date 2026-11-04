import Foundation

// MARK: - PlanScheduleRecord
/// The active plans' schedules in force from `effectiveFrom`, kept with the
/// weekly goal so a closed week's "all scheduled" target counts the plans as
/// they were scheduled that week, not today's plans (ticket 027). A record is
/// written whenever the plans change (`WeeklyGoalHistory.recordingPlans`).
nonisolated struct PlanScheduleRecord: Codable, Equatable, Sendable {
    var effectiveFrom: Date
    /// The active plans, sorted by id so the same plans always compare equal.
    var plans: [ScheduledPlan]

    init(effectiveFrom: Date, plans: [ScheduledPlan]) {
        self.effectiveFrom = effectiveFrom
        self.plans = plans
    }

    /// A record of the active ones among `plans`.
    init(effectiveFrom: Date, activePlansOf plans: [WorkoutPlan]) {
        self.init(effectiveFrom: effectiveFrom, plans: Self.scheduled(plans))
    }

    /// The active plans as the goal needs them, sorted by id.
    static func scheduled(_ plans: [WorkoutPlan]) -> [ScheduledPlan] {
        plans.filter(\.isActive).map(ScheduledPlan.init).sorted { $0.id.uuidString < $1.id.uuidString }
    }
}

// MARK: - ScheduledPlan
/// What the weekly goal needs from a plan: which days it comes up, from when.
/// Done workouts are matched by `id` (`WorkoutLogEntry.planID`).
nonisolated struct ScheduledPlan: Codable, Equatable, Sendable {
    let id: UUID
    let schedule: WorkoutSchedule
    let createdAt: Date

    init(id: UUID, schedule: WorkoutSchedule, createdAt: Date) {
        self.id = id
        self.schedule = schedule
        self.createdAt = createdAt
    }

    init(_ plan: WorkoutPlan) {
        self.init(id: plan.id, schedule: plan.schedule, createdAt: plan.createdAt)
    }

    /// A stand-in plan for `PlanAgenda`, which only reads the id, schedule,
    /// creation date and `isActive`.
    var plan: WorkoutPlan {
        WorkoutPlan(id: id, name: "", schedule: schedule, isActive: true, createdAt: createdAt)
    }
}
