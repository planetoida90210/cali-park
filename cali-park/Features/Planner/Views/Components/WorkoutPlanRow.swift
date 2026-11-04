import SwiftUI

// MARK: - WorkoutPlanRow
/// One saved plan in the list: name, schedule, reminder and exercise count.
struct WorkoutPlanRow: View {
    let plan: WorkoutPlan
    let summary: String
    /// Reminder time, e.g. "18:30", or `nil` without a reminder.
    let reminder: String?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(summary)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)

                if let reminder {
                    Label(reminder, systemImage: "bell")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityLabel("Przypomnienie o \(reminder)")
                }

                // At accessibility sizes the count moves under the name, which
                // keeps the row's full width.
                if typeSize.isAccessibilitySize {
                    exerciseCount
                }
            }

            if !typeSize.isAccessibilitySize {
                Spacer()
                exerciseCount
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private var exerciseCount: some View {
        Text(PolishPlural.exercises(plan.exerciseCount))
            .font(.bodySmall)
            .foregroundStyle(Color.textSecondary)
    }
}
