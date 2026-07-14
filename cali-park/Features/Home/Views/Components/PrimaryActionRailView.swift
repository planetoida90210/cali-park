import SwiftUI

// MARK: - PrimaryActionRailView
/// The two headline actions on Home: start a quick workout, or jump straight
/// into logging the suggested next exercise. Both write through the same
/// dashboard store, so Home refreshes as soon as a sheet closes.
struct PrimaryActionRailView: View {
    let dashboard: HomeDashboardViewModel

    @State private var showingQuickWorkout = false
    @State private var startingPlan: WorkoutPlan?
    @State private var showingPlanEditor = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 8) {
            actionButton(iconName: "bolt.fill", title: "Szybki trening", isPrimary: true) {
                impactFeedback.impactOccurred()
                showingQuickWorkout = true
            }

            actionButton(iconName: "calendar", title: plannerTitle, isPrimary: false) {
                impactFeedback.impactOccurred()
                if let planned = dashboard.nextPlannedWorkout {
                    startingPlan = planned.plan
                } else {
                    // Nothing scheduled yet — go plan one.
                    showingPlanEditor = true
                }
            }
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingQuickWorkout) {
            QuickWorkoutView(
                viewModel: dashboard.makeQuickWorkoutViewModel(),
                onFinish: { dashboard.reload() }
            )
        }
        .sheet(item: $startingPlan, onDismiss: { dashboard.reload() }) { plan in
            QuickWorkoutView(
                viewModel: dashboard.makeQuickWorkoutViewModel(plan: plan),
                onFinish: { dashboard.reload() }
            )
        }
        .sheet(isPresented: $showingPlanEditor, onDismiss: { dashboard.reload() }) {
            PlanEditorView(
                viewModel: dashboard.makePlanEditorViewModel(),
                onSave: { dashboard.reload() }
            )
        }
    }

    /// Shows the scheduled plan's name when one is due, otherwise invites the
    /// user to create a plan.
    private var plannerTitle: String {
        dashboard.nextPlannedWorkout?.plan.name ?? "Zaplanuj trening"
    }

    private func actionButton(
        iconName: String,
        title: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.title3)

                Text(title)
                    .font(.bodySmall)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isPrimary ? Color.accent : Color.componentBackground)
            .foregroundStyle(isPrimary ? Color.black : Color.accent)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accent.opacity(isPrimary ? 0 : 0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    PrimaryActionRailView(dashboard: AppEnvironment.preview.makeHomeDashboardViewModel())
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
