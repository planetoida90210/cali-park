import SwiftUI

// MARK: - PrimaryActionRailView
/// The two headline actions on Home: start a spontaneous quick workout, or open
/// the plans library. Contextual "start today's plan" now lives in the hero, so
/// the second slot is a permanent entry into "Plany" (push `WorkoutPlansView`,
/// which handles its own empty state). Quick workout writes through the same
/// dashboard store, so Home refreshes as soon as the sheet closes.
struct PrimaryActionRailView: View {
    let dashboard: HomeDashboardViewModel

    @State private var showingQuickWorkout = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 8) {
            Button {
                impactFeedback.impactOccurred()
                showingQuickWorkout = true
            } label: {
                railLabel(iconName: "bolt.fill", title: "Szybki trening", isPrimary: true)
            }

            NavigationLink(value: HomeRoute.plans) {
                railLabel(iconName: "calendar", title: "Plany", isPrimary: false)
            }
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingQuickWorkout) {
            QuickWorkoutView(
                viewModel: dashboard.makeQuickWorkoutViewModel(),
                onFinish: { dashboard.reload() }
            )
        }
    }

    private func railLabel(
        iconName: String,
        title: String,
        isPrimary: Bool
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.title3)
                .accessibilityHidden(true)

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

// MARK: - Preview
#Preview {
    NavigationStack {
        PrimaryActionRailView(dashboard: AppEnvironment.preview.makeHomeDashboardViewModel())
            .padding()
            .frame(maxHeight: .infinity)
            .background(Color.appBackground)
    }
    .preferredColorScheme(.dark)
}
