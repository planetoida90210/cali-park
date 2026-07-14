import SwiftUI

// MARK: - PrimaryActionRailView
/// The two headline actions on Home: start a quick workout, or jump straight
/// into logging the suggested next exercise. Both write through the same
/// dashboard store, so Home refreshes as soon as a sheet closes.
struct PrimaryActionRailView: View {
    let dashboard: HomeDashboardViewModel

    @State private var showingQuickWorkout = false
    @State private var loggingExercise: Exercise?

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 8) {
            actionButton(iconName: "bolt.fill", title: "Szybki trening", isPrimary: true) {
                impactFeedback.impactOccurred()
                showingQuickWorkout = true
            }

            actionButton(iconName: "calendar", title: "Nast. trening", isPrimary: false) {
                impactFeedback.impactOccurred()
                if let suggested = dashboard.suggestedExercise {
                    loggingExercise = suggested
                } else {
                    // Nothing suggested yet (empty journal) — start a workout.
                    showingQuickWorkout = true
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
        .sheet(item: $loggingExercise, onDismiss: { dashboard.reload() }) { exercise in
            SetPadSheetView(viewModel: dashboard.makeWorkoutLogViewModel(exercise: exercise))
        }
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
