import SwiftUI

// MARK: - PrimaryActionRailView
/// The two headline actions on Home: start a spontaneous quick workout, or open
/// the plans library. Contextual "start today's plan" now lives in the hero, so
/// the second slot is a permanent entry into "Plany" (push `WorkoutPlansView`,
/// which handles its own empty state). Quick workout writes to the shared
/// journal Home reads, so Home updates as soon as the workout is saved.
struct PrimaryActionRailView: View {
    let dashboard: HomeDashboardViewModel

    @State private var showingQuickWorkout = false
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Side by side; stacked at accessibility text sizes, where two half-width
    /// buttons would cut their titles.
    private var railLayout: AnyLayout {
        typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
    }

    /// Icon above the title; beside it once the buttons are stacked.
    private var labelLayout: AnyLayout {
        typeSize.isAccessibilitySize ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 6))
    }

    var body: some View {
        railLayout {
            Button {
                showingQuickWorkout = true
            } label: {
                railLabel(iconName: "bolt.fill", title: "Szybki trening", isPrimary: true)
            }

            NavigationLink(value: HomeRoute.plans) {
                railLabel(iconName: "calendar", title: "Plany", isPrimary: false)
            }
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.impact(weight: .medium), trigger: showingQuickWorkout) { _, isShowing in
            isShowing
        }
        .sheet(isPresented: $showingQuickWorkout) {
            QuickWorkoutView(viewModel: dashboard.makeQuickWorkoutViewModel())
        }
    }

    private func railLabel(
        iconName: String,
        title: LocalizedStringKey,
        isPrimary: Bool
    ) -> some View {
        labelLayout {
            Image(systemName: iconName)
                .font(.appTitle3)
                .accessibilityHidden(true)

            Text(title)
                .font(.bodySmall)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
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
        PrimaryActionRailView(dashboard: AppEnvironment.previewEmpty.makeHomeDashboardViewModel())
            .padding()
            .frame(maxHeight: .infinity)
            .background(Color.appBackground)
    }
    .preferredColorScheme(.dark)
}
