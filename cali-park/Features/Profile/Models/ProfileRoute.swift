import Foundation

// MARK: - ProfileRoute
/// Push destinations from Profile, resolved with `navigationDestination(for:)`.
nonisolated enum ProfileRoute: Hashable {
    case history
    case backup
    case help
    /// "Diagnostyka", reached from "Pomoc i opinie".
    case diagnostics
    case about
}
