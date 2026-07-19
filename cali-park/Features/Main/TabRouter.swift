import Foundation
import Observation

// MARK: - AppTab
/// The top-level tabs, in bar order. Raw values are the `TabView` selection, so
/// cross-tab navigation (e.g. Home → Skille) stays type-safe instead of leaning
/// on bare integers.
enum AppTab: Int, CaseIterable, Sendable {
    case home
    case parks
    case exercises
    case skills
    case profile
}

// MARK: - TabRouter
/// Shared, observable selection for `MainTabView`, injected into the tab tree so
/// a deep view (the Home achievements module) can switch tabs without threading
/// a binding through every layer.
@MainActor
@Observable
final class TabRouter {
    /// The tab currently shown.
    var selection: AppTab

    init(selection: AppTab = .home) {
        self.selection = selection
    }
}
