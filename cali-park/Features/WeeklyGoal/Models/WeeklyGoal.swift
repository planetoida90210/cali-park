import Foundation

// MARK: - WeeklyGoal
/// One weekly goal: what the athlete wants to do every Monday–Sunday week.
///
/// The athlete keeps one to three goals at a time (`WeeklyGoalVersion`). The
/// `id` survives edits, so a goal changed mid-week is still the same goal for
/// the "already celebrated" bookkeeping.
nonisolated struct WeeklyGoal: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var metric: Metric

    init(id: UUID = UUID(), metric: Metric) {
        self.id = id
        self.metric = metric
    }

    // MARK: Metric
    /// What the goal counts in a week.
    enum Metric: Codable, Hashable, Sendable {
        /// Days with at least one logged workout.
        case trainingDays(days: Int)
        /// Workouts started from a plan.
        case plannedWorkouts(target: PlannedWorkoutsTarget)
        /// Total reps (or seconds held) of one exercise.
        case exerciseVolume(exerciseID: UUID, measurement: ExerciseMeasurement, amount: Int)

        var kind: Kind {
            switch self {
            case .trainingDays: .trainingDays
            case .plannedWorkouts: .plannedWorkouts
            case .exerciseVolume: .exerciseVolume
            }
        }

        /// Whether the target is inside the range the editor offers.
        var isValid: Bool {
            switch self {
            case .trainingDays(let days):
                WeeklyGoal.trainingDaysRange.contains(days)
            case .plannedWorkouts(let target):
                switch target {
                case .allScheduled: true
                case .count(let workouts): WeeklyGoal.plannedWorkoutsRange.contains(workouts)
                }
            case .exerciseVolume(_, _, let amount):
                WeeklyGoal.volumeRange.contains(amount)
            }
        }
    }

    /// How many plan workouts a week asks for.
    enum PlannedWorkoutsTarget: Codable, Hashable, Sendable {
        /// A fixed number of plan workouts, on any days.
        case count(workouts: Int)
        /// Every plan occurrence scheduled in that week.
        case allScheduled
    }

    // MARK: Kind
    /// The three kinds of goal, for the editor's picker.
    enum Kind: String, CaseIterable, Identifiable, Sendable {
        case trainingDays
        case plannedWorkouts
        case exerciseVolume

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .trainingDays: String(localized: "Dni treningowe")
            case .plannedWorkouts: String(localized: "Treningi z planu")
            case .exerciseVolume: String(localized: "Objętość ćwiczenia")
            }
        }

        var symbolName: String {
            switch self {
            case .trainingDays: "calendar"
            case .plannedWorkouts: "list.bullet.clipboard"
            case .exerciseVolume: "chart.bar.fill"
            }
        }

        /// A sensible starting metric when the athlete adds a goal of this kind.
        var defaultMetric: Metric {
            switch self {
            case .trainingDays:
                .trainingDays(days: WeeklyGoal.defaultTrainingDays)
            case .plannedWorkouts:
                .plannedWorkouts(target: .allScheduled)
            case .exerciseVolume:
                .exerciseVolume(exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 50)
            }
        }
    }

    // MARK: Limits
    /// At most this many goals at once; one of them is the primary.
    static let maximumCount = 3
    static let trainingDaysRange = 1...7
    static let plannedWorkoutsRange = 1...14
    static let volumeRange = 1...10_000

    // MARK: Default
    /// Training days per week when nothing is saved and no program says otherwise.
    static let defaultTrainingDays = 3

    /// The fixed id of the implicit default goal, so its celebration mark and
    /// later edits refer to one goal even before anything is saved.
    static let defaultGoalID = UUID(uuidString: "60A1C0DE-0000-4000-8000-000000000001")!

    /// The goal set used while nothing is saved: three training days a week.
    static let defaultGoals = defaultGoals(trainingDaysPerWeek: defaultTrainingDays)

    /// A one-goal set of "N training days a week", clamped to 1–7. Onboarding
    /// and programs call this with the program's weekly frequency.
    static func defaultGoals(trainingDaysPerWeek days: Int) -> [WeeklyGoal] {
        let clamped = min(max(days, trainingDaysRange.lowerBound), trainingDaysRange.upperBound)
        return [WeeklyGoal(id: defaultGoalID, metric: .trainingDays(days: clamped))]
    }

    /// Whether `goals` is a valid set: one to three goals, distinct ids, every
    /// target in range.
    static func isValidSet(_ goals: [WeeklyGoal]) -> Bool {
        (1...maximumCount).contains(goals.count)
            && Set(goals.map(\.id)).count == goals.count
            && goals.allSatisfy(\.metric.isValid)
    }
}
