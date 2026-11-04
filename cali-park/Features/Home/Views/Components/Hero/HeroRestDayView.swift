import SwiftUI

// MARK: - HeroRestDayView
/// Nothing scheduled for today, but a plan is coming up. The hero points to the
/// next session's day, with the weekly goal and its week streak below: rest
/// days never break a week streak. Rest is the message, so there's no CTA.
struct HeroRestDayView: View {
    let nextPlan: WorkoutPlan
    let date: Date
    /// The weekly goal row; `nil` hides it (the goal could not be read).
    let weeklyGoal: WeeklyGoalSnapshot?
    /// Opens the goal editor (long press on the goal row).
    var onEditGoal: () -> Void = {}
    /// A one-line progression nudge, or `nil` when no rung is partway done.
    var progressionHint: String? = nil
    /// Whether "Czas na Fundamenty" is waiting in the Planner; it then takes
    /// the hint's line.
    var showsGraduationHint = false
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(now: now)

                Text("Dziś odpoczywasz")
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Następny trening: \(WorkoutScheduleFormatter.dayLabel(date, asOf: now)) · \(nextPlan.name)")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            HeroHintSlot(showsGraduation: showsGraduationHint, progressionHint: progressionHint)

            if let weeklyGoal {
                Divider().overlay(Color.divider)

                HeroWeeklyGoalView(snapshot: weeklyGoal, onEdit: onEditGoal)
            }
        }
    }
}

// MARK: - Preview
#Preview("Dzień przerwy") {
    HeroRestDayView(
        nextPlan: WorkoutPlan(name: "Pull Day", exercises: [
            PlannedExercise(exerciseID: ExerciseCatalog.pullUpsID)
        ]),
        date: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
        weeklyGoal: WeeklyGoalPreview.running,
        progressionHint: "Jeszcze 5 s do 3 × 20 s — następny szczebel: Advanced tuck front lever"
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: AppRadius.medium))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
