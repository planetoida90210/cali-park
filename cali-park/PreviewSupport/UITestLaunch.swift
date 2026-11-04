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
#endif
