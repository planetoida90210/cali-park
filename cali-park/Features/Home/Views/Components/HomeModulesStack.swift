import SwiftUI

// MARK: - HomeModulesStack
/// The Smart Stack: every enabled Home module in the athlete's order, each one
/// draggable to a new place.
struct HomeModulesStack: View {
    /// Which modules are shown and in what order, shared app-wide.
    let modulePreferences: ModulePreferences
    /// Real journal data for the training modules.
    let dashboard: HomeDashboardViewModel
    /// Builds the view models of the sheets the modules open.
    let environment: AppEnvironment
    /// The nearest Park, for the "parks" module.
    let nearestPark: NearestParkViewModel
    /// The module being dragged to a new place, if any (owned by `HomeView`).
    let moduleDrag: ModuleDragState
    /// Opens the weekly goal editor from the "Cel tygodniowy" module.
    let onEditGoal: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(modulePreferences.enabledModules) { module in
                ModuleView(
                    module: module,
                    dashboard: dashboard,
                    environment: environment,
                    nearestPark: nearestPark,
                    preferences: modulePreferences,
                    isDragging: moduleDrag.liftedID == module.id,
                    onEditGoal: onEditGoal
                )
                .onDrag {
                    let token = moduleDrag.begin(module.id)
                    return ModuleDragItemProvider(module: module) { [moduleDrag] in
                        moduleDrag.end(token)
                    }
                } preview: {
                    ModuleDragPreview(module: module)
                }
                .onDrop(of: [.text], delegate: ModuleDropDelegate(targetID: module.id, drag: moduleDrag, preferences: modulePreferences))
            }
        }
    }
}
