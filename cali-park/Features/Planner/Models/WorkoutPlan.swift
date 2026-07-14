import Foundation

// MARK: - WorkoutPlan
/// A reusable workout the user schedules to repeat (e.g. "every Monday"): a
/// name, the exercises it contains, and a recurrence rule. Persisted via
/// `WorkoutPlanStoring`; the Home screen surfaces the plan whose next
/// occurrence is soonest.
struct WorkoutPlan: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var exercises: [PlannedExercise]
    var schedule: WorkoutSchedule
    /// When `false` the plan is kept but excluded from scheduling.
    var isActive: Bool
    let createdAt: Date
    /// Time of day (hour + minute) for a local reminder, or `nil` for none.
    /// The schedule stays day-granular; this adds the notification's clock time.
    /// Optional so plans saved before reminders existed decode as `nil`.
    var reminderTime: DateComponents?

    init(id: UUID = UUID(),
         name: String,
         exercises: [PlannedExercise] = [],
         schedule: WorkoutSchedule = .once(nil),
         isActive: Bool = true,
         createdAt: Date = .now,
         reminderTime: DateComponents? = nil) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.schedule = schedule
        self.isActive = isActive
        self.createdAt = createdAt
        self.reminderTime = reminderTime
    }

    var exerciseCount: Int { exercises.count }

    /// Sum of prescribed sets across exercises (targets are optional).
    var totalTargetSets: Int {
        exercises.compactMap(\.targetSets).reduce(0, +)
    }

    /// The plan's next scheduled day, or `nil` when inactive or unscheduled.
    func nextOccurrence(onOrAfter reference: Date = .now, calendar: Calendar = .current) -> Date? {
        guard isActive else { return nil }
        return schedule.nextOccurrence(onOrAfter: reference, calendar: calendar)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
