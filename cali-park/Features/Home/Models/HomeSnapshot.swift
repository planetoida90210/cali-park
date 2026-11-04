import Foundation

// MARK: - HomeSnapshot
/// Everything Home derives from the journal, the plans and progress for one
/// calendar day: the hero, the "Następny trening" and "Ostatni trening"
/// modules, the day streak, the achievements and the hint.
///
/// `HomeDashboardViewModel` computes it once per journal revision, plans
/// change, progress revision and day (audit B-14), like
/// `ProgressService.snapshot`, so a render, a module drag or a module
/// expanding reads stored values instead of scanning the journal.
nonisolated struct HomeSnapshot: Equatable {
    let hero: HomeHeroState
    let nextWorkout: NextWorkoutState
    /// The most recent workout, `nil` for an empty journal.
    let latestWorkout: WorkoutSession?
    let streak: WorkoutStreak
    let achievements: HomeAchievementsSummary
    /// The one-line progression nudge, `nil` when no rung is partway done.
    let progressionHint: String?
}

// MARK: - NextWorkoutState
/// What the "Następny trening" module shows.
nonisolated enum NextWorkoutState: Equatable {
    /// A plan to start: the first undone plan due today, else the next
    /// scheduled one.
    case planned(PlanAgenda.Occurrence)
    /// Every plan due today is done. `next` is the following plan, if any,
    /// shown for information only (no start button, so today's plan is
    /// not logged twice by accident).
    case doneToday(plans: [WorkoutPlan], next: PlanAgenda.Occurrence?)
    /// No plans: the untrained-group suggestion.
    case suggestion(Exercise)
    /// Nothing to suggest yet.
    case empty
}

// MARK: - HomeEngine
/// The pure functions behind `HomeSnapshot`. Every date question takes the
/// calendar and the reference date, so tests pin both.
nonisolated enum HomeEngine {
    /// The snapshot for `today`'s calendar day. Only the day of `today`
    /// matters, so any instant on the same day gives the same snapshot.
    /// `entries` are newest first (`TrainingJournal.newestFirst`): that order
    /// lists a workout's exercises and breaks ties between workouts saved at
    /// the same instant.
    static func snapshot(entries: [WorkoutLogEntry],
                         plans: [WorkoutPlan],
                         progress: ProgressSnapshot,
                         calendar: Calendar = .current,
                         today: Date = .now) -> HomeSnapshot {
        let latest = latestWorkout(in: entries)
        let streak = streak(entries: entries, calendar: calendar, today: today)
        let suggestion = suggestedExercise(entries: entries)
        let agendaToday = PlanAgenda.day(today, plans: plans, entries: entries, calendar: calendar)
        let next = PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: calendar, today: today)
        return HomeSnapshot(
            hero: heroState(entries: entries, latestWorkout: latest, streak: streak, suggestion: suggestion,
                            agendaToday: agendaToday, next: next, calendar: calendar, today: today),
            nextWorkout: nextWorkoutState(agendaToday: agendaToday, next: next, suggestion: suggestion),
            latestWorkout: latest,
            streak: streak,
            achievements: achievements(from: progress),
            progressionHint: progress.hint.flatMap(ProgressionFormat.hintLine)
        )
    }

    // MARK: Last workout
    /// The most recent workout for the Home preview: a whole session when the
    /// latest entry belongs to one, otherwise the single standalone entry.
    static func latestWorkout(in entries: [WorkoutLogEntry]) -> WorkoutSession? {
        WorkoutSession.latest(in: entries)
    }

    // MARK: Streak
    static func streak(entries: [WorkoutLogEntry], calendar: Calendar = .current, today: Date = .now) -> WorkoutStreak {
        WorkoutStreak.compute(from: entries.map(\.date), calendar: calendar, today: today)
    }

    // MARK: Suggestion
    /// Heuristic suggestion: the muscle group that has gone untrained the
    /// longest (never-trained groups win), represented by a basic catalog
    /// exercise. `nil` until the journal has at least one entry.
    static func suggestedExercise(entries: [WorkoutLogEntry]) -> Exercise? {
        guard !entries.isEmpty else { return nil }

        var lastTrained: [MuscleGroup: Date] = [:]
        for entry in entries {
            guard let exercise = ExerciseCatalog.exercise(withID: entry.exerciseID) else { continue }
            for group in exercise.muscleGroups {
                lastTrained[group] = max(lastTrained[group] ?? .distantPast, entry.date)
            }
        }

        let staleGroups = MuscleGroup.allCases.sorted {
            (lastTrained[$0] ?? .distantPast) < (lastTrained[$1] ?? .distantPast)
        }

        for group in staleGroups {
            // Prefer a basic exercise that targets the group primarily.
            if let match = ExerciseCatalog.all.first(where: {
                $0.category == .basic && $0.muscleGroups.first == group
            }) {
                return match
            }
            if let match = ExerciseCatalog.all.first(where: {
                $0.category == .basic && $0.muscleGroups.contains(group)
            }) {
                return match
            }
        }
        return nil
    }

    // MARK: Next workout module
    static func nextWorkoutState(entries: [WorkoutLogEntry],
                                 plans: [WorkoutPlan],
                                 calendar: Calendar = .current,
                                 today: Date = .now) -> NextWorkoutState {
        nextWorkoutState(
            agendaToday: PlanAgenda.day(today, plans: plans, entries: entries, calendar: calendar),
            next: PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: calendar, today: today),
            suggestion: suggestedExercise(entries: entries)
        )
    }

    private static func nextWorkoutState(agendaToday: PlanAgenda.Day,
                                         next: PlanAgenda.Occurrence?,
                                         suggestion: Exercise?) -> NextWorkoutState {
        if agendaToday.isAllDone {
            return .doneToday(plans: agendaToday.due, next: next)
        }
        if let next {
            return .planned(next)
        }
        if let suggestion {
            return .suggestion(suggestion)
        }
        return .empty
    }

    // MARK: Hero state
    /// The contextual hero state for `today`'s day, resolved from logs and
    /// plans. Decision tree: an undone plan today → trained today (every plan
    /// due today done, or a free workout)? → any plan ahead? → empty journal?
    static func heroState(entries: [WorkoutLogEntry],
                          plans: [WorkoutPlan],
                          calendar: Calendar = .current,
                          today: Date = .now) -> HomeHeroState {
        heroState(entries: entries,
                  latestWorkout: latestWorkout(in: entries),
                  streak: streak(entries: entries, calendar: calendar, today: today),
                  suggestion: suggestedExercise(entries: entries),
                  agendaToday: PlanAgenda.day(today, plans: plans, entries: entries, calendar: calendar),
                  next: PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: calendar, today: today),
                  calendar: calendar,
                  today: today)
    }

    private static func heroState(entries: [WorkoutLogEntry],
                                  latestWorkout: WorkoutSession?,
                                  streak: WorkoutStreak,
                                  suggestion: Exercise?,
                                  agendaToday: PlanAgenda.Day,
                                  next: PlanAgenda.Occurrence?,
                                  calendar: Calendar,
                                  today: Date) -> HomeHeroState {
        // Q1 — is a plan due today and not done yet? Offer the first one.
        if let planToday = agendaToday.undone.first {
            let entriesToday = entries.filter { calendar.isDate($0.date, inSameDayAs: today) }
            // Holds count too: a hold-only start is still a start (B-12).
            return .planToday(
                plan: planToday,
                loggedTodayReps: entriesToday.reduce(0) { $0 + $1.totalReps },
                loggedTodaySeconds: entriesToday.reduce(0) { $0 + $1.totalSeconds }
            )
        }

        // Q2 — every plan due today is done, or we trained without a plan.
        // A done plan always has an entry today, so this covers both. The
        // newest workout is today's, so it is the summary.
        if streak.trainedDays.contains(calendar.startOfDay(for: today)) {
            guard let latestWorkout else { return .firstRun }
            return .completedToday(summary: latestWorkout, streak: streak)
        }

        // Q3 — nothing today; is any plan scheduled at all?
        if let next {
            return .restDay(nextPlan: next.plan, date: next.date, streak: streak)
        }

        // Q4 — no plans; does the journal hold any history?
        if let latestWorkout {
            return .freeMode(lastWorkout: latestWorkout, suggestion: suggestion, streak: streak)
        }

        return .firstRun
    }

    // MARK: Achievements
    /// Real achievements for the Home module: level, XP to the next level,
    /// badge count, and the most recent conquered rung — all from logs, so
    /// Home mirrors the Skills tab. Declarations grant nothing here.
    static func achievements(from snapshot: ProgressSnapshot) -> HomeAchievementsSummary {
        let level = snapshot.level
        return HomeAchievementsSummary(
            level: level.level,
            xpToNextLevel: level.xpToNextLevel,
            progressToNextLevel: level.progressToNextLevel,
            earnedBadgeCount: snapshot.badges.count,
            totalBadgeCount: Badge.allCases.count,
            lastAdvancement: snapshot.lastAdvancement.flatMap(resolveAdvancement)
        )
    }

    /// Resolves a rung reference into display names from the catalogs.
    private static func resolveAdvancement(_ reference: RungReference) -> HomeAchievementsSummary.Advancement? {
        guard let path = ProgressionCatalog.path(withID: reference.pathID),
              let step = reference.step,
              let exercise = ExerciseCatalog.exercise(withID: step.exerciseID)
        else { return nil }
        return HomeAchievementsSummary.Advancement(
            title: exercise.name,
            pathName: path.name,
            symbolName: path.symbolName
        )
    }
}
