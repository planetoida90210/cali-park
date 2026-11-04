import SwiftUI

// MARK: - ModuleView
/// One Home module: a header that expands and collapses its content. VoiceOver
/// users reorder modules with the "Przesuń wyżej" / "Przesuń niżej" actions on
/// the header; everyone else drags the module or uses the module selection
/// screen.
struct ModuleView: View {
    let module: ModuleDefinition
    /// Real journal data for the training modules.
    let dashboard: HomeDashboardViewModel
    /// The nearest Park, for the "parks" module.
    let nearestPark: NearestParkViewModel
    /// Owns the order, for the move actions.
    let preferences: ModulePreferences
    /// Dims the module while it is being dragged to a new place.
    var isDragging = false
    /// Opens the weekly goal editor from the "Cel tygodniowy" module.
    var onEditGoal: () -> Void = {}

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                ModuleHeaderCard(module: module, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact, trigger: isExpanded)
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue(isExpanded ? "rozwinięty" : "zwinięty")
            .accessibilityActions {
                if preferences.canMoveUp(module.id) {
                    Button("Przesuń wyżej") { move(up: true) }
                }
                if preferences.canMoveDown(module.id) {
                    Button("Przesuń niżej") { move(up: false) }
                }
            }

            if isExpanded {
                moduleContent
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
        .background(Color.appBackground)
        .opacity(isDragging ? 0.35 : 1)
        .animation(.easeOut(duration: 0.15), value: isDragging)
    }

    private func move(up: Bool) {
        withAnimation(.snappy) {
            if up {
                preferences.moveUp(module.id)
            } else {
                preferences.moveDown(module.id)
            }
        }
        guard let index = preferences.enabledModules.firstIndex(of: module.id) else { return }
        AccessibilityNotification.Announcement(
            String(localized: "\(module.name): pozycja \(index + 1) z \(preferences.enabledModules.count)")
        ).post()
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch module.id {
        case "log":
            LastWorkoutModuleContent(dashboard: dashboard)
        case "next":
            NextWorkoutModuleContent(dashboard: dashboard)
        case "parks":
            ParksModuleContent(model: nearestPark)
        case WeeklyGoalModule.id:
            WeeklyGoalModuleContent(snapshot: dashboard.weeklyGoal, onEdit: onEditGoal)
        case "streak":
            StreakModuleContent(streak: dashboard.streak, today: dashboard.now, calendar: dashboard.calendar)
        case "achievements":
            AchievementsModuleContent(summary: dashboard.achievementsSummary)
        default:
            EmptyView()
        }
    }
}

// MARK: - ModuleHeaderCard
/// The module's icon, name and expand chevron on a glass card.
struct ModuleHeaderCard: View {
    let module: ModuleDefinition
    let isExpanded: Bool

    var body: some View {
        HStack {
            Image(systemName: module.iconName)
                .foregroundStyle(Color.accent)
                .font(.appTitle3)
                .accessibilityHidden(true)

            Text(module.name)
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .foregroundStyle(Color.textSecondary)
                .font(.bodyMedium)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
        .background(Color.glassBackground.blur(radius: 30))
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - ModuleDragPreview
/// What follows the finger while a module is dragged: its header, lifted.
struct ModuleDragPreview: View {
    let module: ModuleDefinition

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: module.iconName)
                .foregroundStyle(Color.accent)
                .font(.appTitle3)

            Text(module.name)
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.componentBackground, in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accent.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    let environment = AppEnvironment.seeded()
    let dashboard = environment.makeHomeDashboardViewModel()
    let nearestPark = environment.makeNearestParkViewModel()
    ZStack {
        Color.appBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 0) {
                ForEach(environment.modulePreferences.enabledDefinitions) { module in
                    ModuleView(
                        module: module,
                        dashboard: dashboard,
                        nearestPark: nearestPark,
                        preferences: environment.modulePreferences,
                        isDragging: module.id == "next"
                    )
                }
                ModuleDragPreview(module: ModuleDefinition.allModules[0])
                    .padding()
            }
        }
    }
    .preferredColorScheme(.dark)
}
