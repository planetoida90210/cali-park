import SwiftUI

// MARK: - WorkoutSessionSummaryHeader
/// Top of the workout detail: when it happened and what it added up to
/// ("3 ćwiczenia · 9 serii · 68 powtórzeń").
struct WorkoutSessionSummaryHeader: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.date, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            Text(totals)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var totals: String {
        [
            PolishPlural.exercises(session.entries.count),
            PolishPlural.sets(session.totalSets),
            SetLogFormat.totals(reps: session.totalReps, seconds: session.totalSeconds)
        ]
        .joined(separator: " · ")
    }
}

// MARK: - Preview
#Preview {
    WorkoutSessionSummaryHeader(
        session: WorkoutSession(
            id: UUID(),
            date: .now,
            entries: [
                WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)]),
                WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, sets: [LoggedSet(reps: 12)])
            ]
        )
    )
    .padding(16)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
