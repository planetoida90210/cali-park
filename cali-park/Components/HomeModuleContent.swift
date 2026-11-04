import SwiftUI

// MARK: - HomeModuleContent
/// The expanded body of one Home module: the content view that belongs to the
/// module's kind.
struct HomeModuleContent: View {
    let module: HomeModule
    /// Real journal data for the training modules.
    let dashboard: HomeDashboardViewModel
    /// Builds the view models of the sheets the modules open.
    let environment: AppEnvironment
    /// The nearest Park, for the "parks" module.
    let nearestPark: NearestParkViewModel
    /// Opens the weekly goal editor from the "Cel tygodniowy" module.
    let onEditGoal: () -> Void

    var body: some View {
        switch module {
        case .lastWorkout:
            LastWorkoutModuleContent(dashboard: dashboard)
        case .nextWorkout:
            NextWorkoutModuleContent(dashboard: dashboard, environment: environment)
        case .nearestPark:
            ParksModuleContent(model: nearestPark)
        case .weeklyGoal:
            WeeklyGoalModuleContent(snapshot: dashboard.weeklyGoal, onEdit: onEditGoal)
        case .streak:
            StreakModuleContent(streak: dashboard.streak, today: dashboard.now, calendar: dashboard.calendar)
        case .achievements:
            AchievementsModuleContent(summary: dashboard.achievementsSummary)
        }
    }
}
