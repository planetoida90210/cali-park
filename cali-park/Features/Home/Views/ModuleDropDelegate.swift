import SwiftUI
import UniformTypeIdentifiers

// MARK: - ModuleDropDelegate
/// Reorders Home modules while one is dragged. Placed on each module
/// (`targetID` set) and on the Home content around them (`targetID` nil), so a
/// drop anywhere on Home ends the drag. Only drags started on Home are
/// accepted; text dropped from another app is rejected.
@MainActor
struct ModuleDropDelegate: DropDelegate {
    /// The module under the finger, or nil for the area around the modules.
    let targetID: String?
    let drag: ModuleDragState
    let preferences: ModulePreferences

    func validateDrop(info: DropInfo) -> Bool {
        drag.draggingID != nil && info.hasItemsConforming(to: [.text])
    }

    func dropEntered(info: DropInfo) {
        guard let targetID else { return }
        withAnimation(.snappy) {
            drag.enter(targetID, in: preferences)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: drag.draggingID == nil ? .forbidden : .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        let accepted = drag.draggingID != nil
        drag.clear()
        return accepted
    }
}

// MARK: - ModuleDragItemProvider
/// The item provider of a module drag. Before iOS 27 SwiftUI has no callback
/// for the end of a drag, but the system releases the provider once the drag
/// session is over, whether it was dropped or cancelled, so `deinit` reports
/// the end. The module ID is visible to this app only.
final class ModuleDragItemProvider: NSItemProvider {
    private let onEnd: @MainActor @Sendable () -> Void

    init(moduleID: String, onEnd: @escaping @MainActor @Sendable () -> Void) {
        self.onEnd = onEnd
        super.init()
        registerObject(moduleID as NSString, visibility: .ownProcess)
    }

    deinit {
        let onEnd = onEnd
        Task { @MainActor in onEnd() }
    }
}
