import SwiftUI

struct ModuleDropDelegate: DropDelegate {
    let item: String                // ID modułu nad którym odbywa się drop
    @Binding var draggingItem: String?
    let prefs: ModulePreferences
    
    func dropEntered(info: DropInfo) {
        guard let draggingItem, draggingItem != item,
              let fromIndex = prefs.enabledModules.firstIndex(of: draggingItem),
              let toIndex = prefs.enabledModules.firstIndex(of: item) else { return }
        
        withAnimation {
            prefs.enabledModules.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
} 