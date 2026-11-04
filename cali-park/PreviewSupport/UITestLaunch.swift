#if DEBUG
import Foundation

// MARK: - UITestSeed
/// The starting data for a UI test run. `cali-parkUITests` launches the app
/// with `-uitest-reset` and names a seed in the `CALIPARK_UITEST_SEED`
/// environment value (`fresh` when it is missing). The app then runs on
/// in-memory stores and its own cleared `UserDefaults` suite, so every test
/// starts from the same state and never touches the real store files,
/// settings or reminders. Debug builds only.
nonisolated enum UITestSeed: String, CaseIterable, Sendable {
    /// Nothing saved: the app opens on onboarding.
    case fresh
    /// Onboarding done, no plans, an empty journal.
    case onboarded
    /// Onboarding done and a one-off plan ("Push Day") due today.
    case planToday
    /// Onboarding done and a seasoned athlete's journal: full pull-ups
    /// conquered (3 × 8) on a "Pierwsze podciągnięcie" plan scheduled on
    /// every day but today, so Home rests and offers "Czas na Fundamenty".
    case veteran
    /// Onboarding done and five weeks of "Fundamenty" three times a week,
    /// for the App Store screenshots: the plan is due today and not done
    /// yet, the weekly goal has a five-week streak, and the pull-up ladder
    /// stands on full pull-ups at 3 × 6 after conquering the negatives.
    case storeTour

    /// The launch argument that turns the seeded launch on.
    static let resetArgument = "-uitest-reset"
    /// The environment value naming the seed.
    static let environmentKey = "CALIPARK_UITEST_SEED"
    /// The `UserDefaults` suite a seeded launch uses, cleared on every launch.
    static let defaultsSuiteName = "cali-park.uitests"

    /// The seed this process was launched with, or `nil` for a normal launch.
    /// An unknown seed name stops the app, so a typo in a test fails loudly
    /// instead of quietly testing the wrong state.
    static func requested(arguments: [String], environment: [String: String]) -> UITestSeed? {
        guard arguments.contains(resetArgument) else { return nil }
        guard let name = environment[environmentKey] else { return .fresh }
        guard let seed = UITestSeed(rawValue: name) else {
            preconditionFailure("Unknown \(environmentKey) \"\(name)\"; expected one of \(allCases.map(\.rawValue))")
        }
        return seed
    }

    /// Whether onboarding counts as finished in this seed.
    var hasCompletedOnboarding: Bool { self != .fresh }
}

// MARK: - Seeded launch
extension AppEnvironment {
    /// The environment for a UI test launch: `seeded(...)` with `seed`'s data,
    /// writing its flags to `defaults`. The app passes `uiTestDefaults()`;
    /// unit tests pass a throwaway suite.
    static func uiTest(_ seed: UITestSeed,
                       defaults: UserDefaults,
                       calendar: Calendar = .current,
                       now: Date = .now) -> AppEnvironment {
        defaults.set(seed.hasCompletedOnboarding, forKey: DefaultsKey.hasCompletedOnboarding.rawValue)
        switch seed {
        case .fresh, .onboarded:
            return seeded(defaults: defaults)
        case .planToday:
            return seeded(plans: [planForToday(calendar: calendar, now: now)], defaults: defaults)
        case .veteran:
            // Logged yesterday, so today is still a rest day.
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return seeded(logs: veteranLogs(at: yesterday) + [Self.fullPullUps(at: yesterday)],
                          plans: [firstPullUpPlan(restingOn: now, calendar: calendar)],
                          placement: veteranPlacement,
                          defaults: defaults)
        case .storeTour:
            let tour = StoreTour(calendar: calendar, now: now)
            return seeded(logs: tour.logs, plans: [tour.plan], placement: StoreTour.placement, defaults: defaults)
        }
    }

    /// The UI tests' `UserDefaults` suite, emptied, so nothing a previous
    /// run set (onboarding, Home modules, dismissed cards) leaks into the next.
    static func uiTestDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: UITestSeed.defaultsSuiteName) else {
            preconditionFailure("UserDefaults refused the suite \(UITestSeed.defaultsSuiteName)")
        }
        defaults.removePersistentDomain(forName: UITestSeed.defaultsSuiteName)
        return defaults
    }

    /// 3 × 8 full pull-ups at `date`: "Pierwsze podciągnięcie" is done.
    private static func fullPullUps(at date: Date) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, date: date,
                        sets: Array(repeating: LoggedSet(reps: 8), count: 3))
    }

    /// A "Pierwsze podciągnięcie" plan on every weekday except `now`'s, so
    /// today is a rest day whatever the weekday.
    private static func firstPullUpPlan(restingOn now: Date, calendar: Calendar) -> WorkoutPlan {
        var plan = ProgramPrescriber.plans(for: ProgramCatalog.firstPullUp, pathStates: [:], today: now)[0]
        let today = Weekday(rawValue: calendar.component(.weekday, from: now))
        plan.schedule = .weekly(Set(Weekday.allCases.filter { $0 != today }))
        return plan
    }
}

// MARK: - StoreTour
/// The athlete of the `storeTour` seed: a "Fundamenty" plan on Monday,
/// Wednesday, Friday and today, five full weeks of its sessions before this
/// week, and this week's Monday and yesterday when they come before today.
/// So the weekly goal (the implicit three training days) has a five-week
/// streak and stands at 0–2 of 3 this week, and today's plan is still to do.
nonisolated struct StoreTour {
    /// Full weeks of training before the current one.
    static let fullWeeks = 5
    /// The rungs the athlete declared at the start: negative pull-ups,
    /// split squats, push-ups, dips, hanging knee raises and Australian rows.
    static let placement = SkillPlacement(
        declaredRungByPath: [.pullUp: 3, .legs: 3, .pushUp: 3, .dip: 2, .core: 1, .row: 1]
    )

    let plan: WorkoutPlan
    let logs: [WorkoutLogEntry]

    init(calendar: Calendar, now: Date) {
        let today = calendar.startOfDay(for: now)
        let weekStart = WeeklyGoalEvaluator.week(containing: today, calendar: calendar).start
        let trainingDays: Set<Weekday> = [.monday, .wednesday, .friday]
        let todayWeekday = Weekday(rawValue: calendar.component(.weekday, from: today)) ?? .monday

        var plan = ProgramPrescriber.plans(
            for: ProgramCatalog.fundamentals,
            pathStates: ProgressionEngine.pathStates(logs: [], placement: Self.placement),
            today: now
        )[0]
        plan.schedule = .weekly(trainingDays.union([todayWeekday]))
        self.plan = plan

        func day(_ offset: Int, from start: Date) -> Date? {
            calendar.date(byAdding: .day, value: offset, to: start)
        }
        // Monday, Wednesday and Friday of each full week, oldest first.
        var days: [Date] = (1...Self.fullWeeks).reversed().flatMap { weeksBack in
            [0, 2, 4].compactMap { day($0 - 7 * weeksBack, from: weekStart) }
        }
        // This week: Monday and yesterday, whichever come before today.
        let yesterday = day(-1, from: today) ?? today
        days += Set([weekStart, yesterday]).filter { $0 >= weekStart && $0 < today }.sorted()

        self.logs = days.enumerated().flatMap { index, date in
            Self.session(index, at: calendar.date(byAdding: .hour, value: 18, to: date) ?? date, planID: plan.id)
        }
    }

    /// The `index`th "Fundamenty" session. Negative pull-ups reach 3 × 5 in
    /// the fourth session and give way to full pull-ups, which climb from
    /// 3 × 3 to 3 × 6; the other rungs grow slowly and stay below 3 × 8.
    static func session(_ index: Int, at date: Date, planID: UUID) -> [WorkoutLogEntry] {
        let sessionID = UUID()
        func entry(_ exerciseID: UUID, _ reps: Int) -> WorkoutLogEntry {
            WorkoutLogEntry(exerciseID: exerciseID, date: date,
                            sets: Array(repeating: LoggedSet(reps: reps), count: 3),
                            sessionID: sessionID, planID: planID)
        }
        let pullUps = index < 4
            ? entry(ExerciseCatalog.negativePullUpsID, 2 + index)
            : entry(ExerciseCatalog.pullUpsID, min(6, 3 + (index - 4) / 3))
        let steady = min(7, 4 + index / 4)
        return [
            pullUps,
            entry(ExerciseCatalog.splitSquatID, steady),
            entry(ExerciseCatalog.dipsID, steady - 1),
            entry(ExerciseCatalog.hangingKneeRaisesID, steady),
            entry(ExerciseCatalog.australianPullUpsID, steady),
            entry(ExerciseCatalog.pushUpsID, steady)
        ]
    }
}
#endif
