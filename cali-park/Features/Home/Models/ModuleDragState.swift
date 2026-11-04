import Foundation
import Observation

// MARK: - ModuleDragState
/// The Home module being dragged to a new place, if any.
///
/// SwiftUI asks for a drag item (`begin`) whenever a drag might start, also
/// right after a drop, when no drag follows. So the module is only shown as
/// lifted (`liftedID`, dimmed in place) once a drop target on Home has seen
/// the drag (`enter`).
///
/// A drag ends on a drop (`performDrop`) or when the system releases the drag
/// item provider, which also covers a cancelled drag and a drop outside Home.
/// Each drag gets a token, so the late end of an earlier drag never cancels
/// the current one.
@MainActor
@Observable
final class ModuleDragState {
    /// The ID of the module a drag was requested for.
    private(set) var draggingID: String?
    /// Whether a drop target on Home has seen the drag.
    private(set) var isActive = false
    @ObservationIgnored private var token: UUID?

    /// The module to show as lifted, while a drag is really in progress.
    var liftedID: String? { isActive ? draggingID : nil }

    /// Starts dragging `id` and returns the token that ends this drag.
    func begin(_ id: String) -> UUID {
        let token = UUID()
        self.token = token
        draggingID = id
        isActive = false
        return token
    }

    /// Ends the drag started with `token`; a stale token does nothing.
    func end(_ token: UUID) {
        guard token == self.token else { return }
        clear()
    }

    /// Ends whatever drag is in progress (a drop).
    func clear() {
        token = nil
        draggingID = nil
        isActive = false
    }

    /// The finger entered `target` while dragging: the drag is real, and the
    /// dragged module takes the target's place. Does nothing outside a drag,
    /// so a drop from another app never reorders anything.
    func enter(_ target: String, in preferences: ModulePreferences) {
        guard let draggingID else { return }
        isActive = true
        preferences.move(draggingID, onto: target)
    }
}
