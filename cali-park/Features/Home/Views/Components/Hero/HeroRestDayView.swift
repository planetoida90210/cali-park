import SwiftUI

// MARK: - HeroRestDayView
/// Nothing scheduled for today, but a plan is coming up. The hero keeps the
/// streak alive in view and points to the next session's day, with the weekly
/// goal as a secondary line. Rest is the message, so there's no CTA.
struct HeroRestDayView: View {
    let nextPlan: WorkoutPlan
    let date: Date
    let streak: WorkoutStreak
    let name: String
    let weeklyReps: Int
    let weeklyProgress: Double
    /// A one-line progression nudge, or `nil` when no rung is partway done.
    var progressionHint: String? = nil
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HeroHeaderView(name: name, now: now)

                Text("Dziś odpoczywasz")
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)

                Text("Następny trening: \(WorkoutScheduleFormatter.dayLabel(date, asOf: now)) · \(nextPlan.name)")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            if let progressionHint {
                HeroProgressionHintView(hint: progressionHint)
            }

            HeroStreakLabel(streak: streak)

            Divider().overlay(Color.divider)

            HeroWeeklyRingView(weeklyReps: weeklyReps, progress: weeklyProgress)
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
        streak: WorkoutStreak(current: 3, longest: 7, trainedDays: []),
        name: "Michał",
        weeklyReps: 18,
        weeklyProgress: 0.3,
        progressionHint: "Jeszcze 5 s do 3 × 20 s — następny szczebel: Advanced tuck front lever"
    )
    .padding(20)
    .background(Color.componentBackground)
    .clipShape(.rect(cornerRadius: 12))
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
