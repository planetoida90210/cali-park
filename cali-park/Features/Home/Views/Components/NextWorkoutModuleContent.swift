import SwiftUI

// MARK: - Next Workout Module
/// Shows what to train next. A scheduled plan wins (name, when, and a
/// "Rozpocznij" that opens the session prefilled from the plan). When every
/// plan due today is done it says so instead of offering it again. Without
/// plans it falls back to the untrained-group suggestion, then an honest empty
/// state.
struct NextWorkoutModuleContent: View {
    let dashboard: HomeDashboardViewModel
    /// Builds the SetPad and quick workout view models for the sheets.
    let environment: AppEnvironment

    /// Payload-driven sheets — set only when an action starts.
    @State private var loggingExercise: Exercise?
    @State private var startingPlan: WorkoutPlan?

    var body: some View {
        Group {
            switch dashboard.nextWorkoutState {
            case .planned(let planned):
                PlannedWorkoutContent(planned: planned, today: dashboard.now, calendar: dashboard.calendar) {
                    startingPlan = planned.plan
                }
            case .doneToday(let plans, let next):
                DoneTodayContent(plans: plans, next: next, today: dashboard.now, calendar: dashboard.calendar)
            case .suggestion(let suggestion):
                SuggestionContent(exercise: suggestion) {
                    loggingExercise = suggestion
                }
            case .empty:
                NextWorkoutEmptyState()
            }
        }
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .sheet(item: $loggingExercise) { exercise in
            SetPadSheetView(viewModel: environment.makeWorkoutLogViewModel(exercise: exercise))
        }
        .sheet(item: $startingPlan) { plan in
            QuickWorkoutView(viewModel: environment.makeQuickWorkoutViewModel(plan: plan))
        }
    }
}

// MARK: - PlannedWorkoutContent
private struct PlannedWorkoutContent: View {
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

// MARK: - DoneTodayContent
/// Every plan due today is logged: confirm it, and name the next plan without
/// a start button so today's plan is not logged twice by accident.
private struct DoneTodayContent: View {
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
    }
}

// MARK: - SuggestionContent
private struct SuggestionContent: View {
    let exercise: Exercise
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ExerciseIconView(symbolName: exercise.symbolName, size: .row)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("Najdłużej nietrenowane: \(exercise.muscleGroups.map(\.displayName).joined(separator: ", "))")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()
            }

            Button("Zaloguj serię", action: onLog)
                .buttonStyle(.accent(.compact))
        }
    }
}

// MARK: - NextWorkoutEmptyState
private struct NextWorkoutEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.appTitle2)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)

            Text("Brak propozycji")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zaloguj pierwszy trening lub zaplanuj kolejny.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    let environment = AppEnvironment.previewPlanToday
    NextWorkoutModuleContent(dashboard: environment.makeHomeDashboardViewModel(), environment: environment)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
