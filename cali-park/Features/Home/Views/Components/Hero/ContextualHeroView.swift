import SwiftUI

// MARK: - ContextualHeroView
/// The Home hero, rebuilt to react to context instead of always showing the
/// same greeting + weekly count. It is a "dumb" view: it renders a resolved
/// `HomeHeroState` (from `HomeDashboardViewModel.heroState(asOf:)`) inside one
/// shared card frame and forwards taps through closures, which `HomeView`
/// wires to starting a plan or a quick workout.
///
/// The weekly goal lives *outside* the state (on the view model), so it is
/// passed in here and shown as a secondary row, with the week streak, in every
/// state (ticket 027: the hero always carries the primary goal's ring). In
/// "plan today" it sits below "Rozpocznij", so the button stays the headline.
struct ContextualHeroView: View {
    let state: HomeHeroState
    /// `nil` hides the goal row (the goal could not be read).
    let weeklyGoal: WeeklyGoalSnapshot?
    /// A one-line progression nudge shown on rest / free-training days, e.g.
    /// "Jeszcze 2 powtórzenia do 3 × 8 — następny szczebel: …". `nil` hides it.
    var progressionHint: String? = nil
    /// Whether the Planner's "Czas na Fundamenty" card is waiting; the hint
    /// line then leads to the plans instead.
    var showsGraduationHint = false
    var now: Date = .now

    /// Only the contextual "start today's plan" is a hero action. The
    /// spontaneous quick workout and plan management live permanently in the
    /// rail below, so the hero doesn't duplicate them.
    var onStartPlan: (WorkoutPlan) -> Void = { _ in }
    /// Opens the weekly goal editor (long press on the goal row).
    var onEditGoal: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HeroStateContent(
            state: state,
            weeklyGoal: weeklyGoal,
            progressionHint: progressionHint,
            showsGraduationHint: showsGraduationHint,
            now: now,
            onStartPlan: onStartPlan,
            onEditGoal: onEditGoal
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.hero.\(stateName)")
        .id(stateID)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: stateID)
    }

    /// The state's name in the hero's accessibility identifier, which the UI
    /// tests read ("home.hero.planToday").
    private var stateName: String {
        switch state {
        case .planToday: "planToday"
        case .completedToday: "completedToday"
        case .restDay: "restDay"
        case .freeMode: "freeMode"
        case .firstRun: "firstRun"
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
    static let planToday = HomeHeroState.planToday(
        plan: WorkoutPlan(name: "Push Day", exercises: [
            PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID),
            PlannedExercise(exerciseID: ExerciseCatalog.dipsID),
            PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)
        ]),
        loggedTodayReps: 24
    )

    static let completedToday = HomeHeroState.completedToday(
        summary: WorkoutSession(
            id: sharedSession,
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
        lastWorkout: WorkoutSession(
            id: UUID(),
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
            entries: [WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 7)])]
        ),
        suggestion: ExerciseCatalog.exercise(withID: ExerciseCatalog.squatsID),
        streak: WorkoutStreak(current: 0, longest: 6, trainedDays: [])
    )

    static let firstRun = HomeHeroState.firstRun

    private static let sharedSession = UUID()

    @ViewBuilder
    static func card(_ state: HomeHeroState, weeklyGoal: WeeklyGoalSnapshot = WeeklyGoalPreview.running) -> some View {
        ContextualHeroView(
            state: state,
            weeklyGoal: weeklyGoal
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

#Preview("Plan dziś · AX5") {
    ScrollView {
        HeroPreview.card(HeroPreview.planToday)
            .padding()
    }
    .background(Color.appBackground)
    .dynamicTypeSize(.accessibility5)
    .preferredColorScheme(.dark)
}


#Preview("Zrobione dziś") {
    HeroPreview.card(HeroPreview.completedToday)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Dzień przerwy") {
    HeroPreview.card(HeroPreview.restDay, weeklyGoal: WeeklyGoalPreview.met)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Wolny tryb") {
    HeroPreview.card(HeroPreview.freeMode, weeklyGoal: WeeklyGoalPreview.paused)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}

#Preview("Pierwszy start") {
    HeroPreview.card(HeroPreview.firstRun)
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
            HeroPreview.card(HeroPreview.restDay, weeklyGoal: WeeklyGoalPreview.met)
            HeroPreview.card(HeroPreview.freeMode, weeklyGoal: WeeklyGoalPreview.paused)
            HeroPreview.card(HeroPreview.firstRun)
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
