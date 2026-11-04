import SwiftUI

// MARK: - WorkoutSessionExerciseRow
/// One exercise inside a workout: name, the set-by-set breakdown and its total.
struct WorkoutSessionExerciseRow: View {
    let entry: WorkoutLogEntry
    let exercise: Exercise?

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(
                symbolName: exercise?.symbolName ?? ExerciseCatalog.unknownSymbolName,
                size: .row
            )

            AdaptiveDetailRow {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise?.name ?? ExerciseCatalog.unknownName)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(PolishPlural.sets(entry.sets.count)): \(MeasureFormat.breakdown(of: entry.sets))")
                        .font(.bodySmall)
                        .monospacedDigit()
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityLabel(MeasureFormat.spokenSetLine(of: entry.sets))
                }
            } details: {
                Text(MeasureFormat.total(of: entry.sets))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    List {
        WorkoutSessionExerciseRow(
            entry: WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 8)]
            ),
            exercise: ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)
        )
    }
    .preferredColorScheme(.dark)
}
