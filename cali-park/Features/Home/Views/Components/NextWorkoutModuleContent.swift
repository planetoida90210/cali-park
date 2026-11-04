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
                NextWorkoutPlannedContent(planned: planned, today: dashboard.now, calendar: dashboard.calendar) {
                    startingPlan = planned.plan
                }
            case .doneToday(let plans, let next):
                NextWorkoutDoneTodayContent(plans: plans, next: next, today: dashboard.now, calendar: dashboard.calendar)
            case .suggestion(let suggestion):
                NextWorkoutSuggestionContent(exercise: suggestion) {
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

#if DEBUG
// MARK: - Preview
#Preview {
    let environment = AppEnvironment.previewPlanToday
    NextWorkoutModuleContent(dashboard: environment.makeHomeDashboardViewModel(), environment: environment)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
#endif
