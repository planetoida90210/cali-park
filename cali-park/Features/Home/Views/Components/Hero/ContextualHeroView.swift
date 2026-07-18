import SwiftUI

// MARK: - ContextualHeroView
/// The Home hero, rebuilt to react to context instead of always showing the
/// same greeting + weekly count. It is a "dumb" view: it renders a resolved
/// `HomeHeroState` (from `HomeDashboardViewModel.heroState(asOf:)`) inside one
/// shared card frame and forwards taps through closures. Wiring it into
/// `HomeView` happens in Sprint H3 — for now it drives the previews below.
///
/// Weekly pull-ups and the goal ring live *outside* the state (on the view
/// model), so they're passed in here and demoted to a secondary line in the
/// states that show them (completed / rest / free mode).
struct ContextualHeroView: View {
    let state: HomeHeroState
    let name: String
    let weeklyReps: Int
    let weeklyProgress: Double
    var now: Date = .now

    /// Only the contextual "start today's plan" is a hero action. The
    /// spontaneous quick workout and plan management live permanently in the
    /// rail below, so the hero doesn't duplicate them.
    var onStartPlan: (WorkoutPlan) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.componentBackground)
            .clipShape(.rect(cornerRadius: 12))
            .id(stateID)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: stateID)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case let .planToday(plan, loggedTodayReps):
            HeroPlanTodayView(
                plan: plan,
                loggedTodayReps: loggedTodayReps,
                name: name,
                now: now,
                onStart: { onStartPlan(plan) }
            )

        case let .completedToday(summary, streak):
            HeroCompletedTodayView(
                summary: summary,
                streak: streak,
                name: name,
                weeklyReps: weeklyReps,
                weeklyProgress: weeklyProgress,
                now: now
            )

        case let .restDay(nextPlan, date, streak):
            HeroRestDayView(
                nextPlan: nextPlan,
                date: date,
                streak: streak,
                name: name,
                weeklyReps: weeklyReps,
                weeklyProgress: weeklyProgress,
                now: now
            )

        case let .freeMode(lastWorkout, suggestion, streak):
            HeroFreeModeView(
                lastWorkout: lastWorkout,
                suggestion: suggestion,
                streak: streak,
                name: name,
                weeklyReps: weeklyReps,
                weeklyProgress: weeklyProgress,
                now: now
            )

        case .firstRun:
            HeroFirstRunView(name: name, now: now)
        }
    }

    /// A stable discriminator per case so a state change gets a fresh identity
    /// and animates via `.transition`, without animating unrelated updates
    /// (e.g. a reps count ticking up within the same case).
    private var stateID: Int {
        switch state {
        case .planToday: 0
        case .completedToday: 1
        case .restDay: 2
        case .freeMode: 3
        case .firstRun: 4
        }
    }
}

// MARK: - Preview sample data
/// Preview-only fixtures so each hero state can be eyeballed without seeding a
/// store. The real states come from `heroState(asOf:)` in the app.
private enum HeroPreview {
    static let name = "Michał"

    static let planToday = HomeHeroState.planToday(
        plan: WorkoutPlan(name: "Push Day", exercises: [
            PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID),
            PlannedExercise(exerciseID: ExerciseCatalog.dipsID),
            PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)
        ]),
        loggedTodayReps: 24
    )

    static let completedToday = HomeHeroState.completedToday(
        summary: HomeDashboardViewModel.LatestWorkout(
            date: .now,
            entries: [
                WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)], sessionID: sharedSession),
                WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, sets: [LoggedSet(reps: 12)], sessionID: sharedSession)
            ]
        ),
        streak: WorkoutStreak(current: 5, longest: 9, trainedDays: [])
    )

    static let restDay = HomeHeroState.restDay(
        nextPlan: WorkoutPlan(name: "Pull Day", exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)]),
        date: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
        streak: WorkoutStreak(current: 3, longest: 7, trainedDays: [])
    )

    static let freeMode = HomeHeroState.freeMode(
        lastWorkout: HomeDashboardViewModel.LatestWorkout(
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
            entries: [WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 7)])]
        ),
        suggestion: ExerciseCatalog.exercise(withID: ExerciseCatalog.squatsID),
        streak: WorkoutStreak(current: 0, longest: 6, trainedDays: [])
    )

    static let firstRun = HomeHeroState.firstRun

    private static let sharedSession = UUID()

    @ViewBuilder
    static func card(_ state: HomeHeroState, weeklyReps: Int = 42, weeklyProgress: Double = 0.6) -> some View {
        ContextualHeroView(
            state: state,
            name: name,
            weeklyReps: weeklyReps,
            weeklyProgress: weeklyProgress
        )
    }
}

// MARK: - Previews (per state)
#Preview("Plan dziś") {
    HeroPreview.card(HeroPreview.planToday)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Zrobione dziś") {
    HeroPreview.card(HeroPreview.completedToday)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Dzień przerwy") {
    HeroPreview.card(HeroPreview.restDay, weeklyReps: 18, weeklyProgress: 0.3)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Wolny tryb") {
    HeroPreview.card(HeroPreview.freeMode, weeklyReps: 15, weeklyProgress: 0.25)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Pierwszy start") {
    HeroPreview.card(HeroPreview.firstRun, weeklyReps: 0, weeklyProgress: 0)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

// MARK: - Preview (gallery: every state at once)
#Preview("Galeria stanów") {
    ScrollView {
        VStack(spacing: 16) {
            HeroPreview.card(HeroPreview.planToday)
            HeroPreview.card(HeroPreview.completedToday)
            HeroPreview.card(HeroPreview.restDay, weeklyReps: 18, weeklyProgress: 0.3)
            HeroPreview.card(HeroPreview.freeMode, weeklyReps: 15, weeklyProgress: 0.25)
            HeroPreview.card(HeroPreview.firstRun, weeklyReps: 0, weeklyProgress: 0)
        }
        .padding()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview (interactive: tap to cycle states, see transitions)
#Preview("Przejścia stanów") {
    struct TransitionDemo: View {
        private let states: [HomeHeroState] = [
            HeroPreview.planToday,
            HeroPreview.completedToday,
            HeroPreview.restDay,
            HeroPreview.freeMode,
            HeroPreview.firstRun
        ]
        @State private var index = 0

        var body: some View {
            VStack(spacing: 20) {
                HeroPreview.card(states[index])

                Button("Następny stan", systemImage: "arrow.right.circle") {
                    index = (index + 1) % states.count
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }
            .padding()
            .frame(maxHeight: .infinity)
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
        }
    }
    return TransitionDemo()
}
