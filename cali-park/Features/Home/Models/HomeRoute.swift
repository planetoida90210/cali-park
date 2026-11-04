import Foundation

// MARK: - HomeRoute
/// Push destinations from Home. The primary action rail's "Plany" button
/// resolves to `.plans`; kept type-safe via `navigationDestination(for:)`.
enum HomeRoute: Hashable {
    case plans
}
