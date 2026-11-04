import SwiftUI

// MARK: - NextWorkoutPlannedContent
/// The next scheduled plan: its name, when it is due, and "Rozpocznij".
struct NextWorkoutPlannedContent: View {
    let planned: PlanAgenda.Occurrence
    let today: Date
    let calendar: Calendar
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.appTitle3)
                    .foregroundStyle(Color.black)
                    .scaledIconFrame(44, relativeTo: .title3)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: AppRadius.medium))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(planned.plan.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(WorkoutScheduleFormatter.dayLabel(planned.date, asOf: today, calendar: calendar)) · \(PolishPlural.exercises(planned.plan.exerciseCount))")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()
            }

            Button("Rozpocznij", action: onStart)
                .buttonStyle(.accent(.compact))
        }
    }
}
