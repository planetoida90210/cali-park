import SwiftUI

// MARK: - NextWorkoutDoneTodayContent
/// Every plan due today is logged: confirm it, and name the next plan without
/// a start button so today's plan is not logged twice by accident.
struct NextWorkoutDoneTodayContent: View {
    let plans: [WorkoutPlan]
    let next: PlanAgenda.Occurrence?
    let today: Date
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.appTitle3)
                .foregroundStyle(Color.black)
                .scaledIconFrame(44, relativeTo: .title3)
                .background(Color.accent)
                .clipShape(.rect(cornerRadius: AppRadius.medium))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Dziś · Zrobione")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(plans.map(\.name).joined(separator: ", "))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)

                if let next {
                    Text("Następny: \(WorkoutScheduleFormatter.dayLabel(next.date, asOf: today, calendar: calendar)) · \(next.plan.name)")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.nextWorkout.doneToday")
    }
}
