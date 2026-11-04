import Foundation
import Observation

// MARK: - ModulePreferences
/// Which Home modules are shown, and in what order. Created once in
/// `AppEnvironment` and passed explicitly to Home and the module selection
/// screen.
///
/// Stored in `UserDefaults` under `DefaultsKey.enabledModules` as an array of module IDs in
/// display order (the format every earlier build wrote), so existing users
/// keep their choices. IDs of modules that no longer exist (the retired
/// leaderboard and feed) and duplicates are dropped on load.
@MainActor
@Observable
final class ModulePreferences {
    /// What a fresh install shows, until the athlete changes anything.
    static let defaultModuleIDs = ["log", "next", WeeklyGoalModule.id, "parks"]

    /// The IDs of the shown modules, in display order.
    private(set) var enabledModules: [String]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        guard let saved = defaults.stringArray(forKey: DefaultsKey.enabledModules.rawValue) else {
            // Nothing is written until the athlete changes something, so a
            // later change of the defaults still reaches untouched installs.
            enabledModules = Self.defaultModuleIDs
            return
        }
        let known = Set(ModuleDefinition.allModules.map(\.id))
        var seen = Set<String>()
        let cleaned = saved.filter { known.contains($0) && seen.insert($0).inserted }
        enabledModules = cleaned
        if cleaned != saved { save() }
    }

    // MARK: Queries
    /// The shown modules, in display order.
    var enabledDefinitions: [ModuleDefinition] {
        enabledModules.compactMap(ModuleDefinition.module(withID:))
    }

    /// The hidden modules, in catalog order.
    var disabledDefinitions: [ModuleDefinition] {
        ModuleDefinition.allModules.filter { !enabledModules.contains($0.id) }
    }

    func isEnabled(_ id: String) -> Bool {
        enabledModules.contains(id)
    }

    func canMoveUp(_ id: String) -> Bool {
        guard let index = enabledModules.firstIndex(of: id) else { return false }
        return index > 0
    }

    func canMoveDown(_ id: String) -> Bool {
        guard let index = enabledModules.firstIndex(of: id) else { return false }
        return index < enabledModules.count - 1
    }

    // MARK: Intentions
    /// Shows a module (at the end) or hides it. Unknown IDs are ignored.
    func setEnabled(_ enabled: Bool, for id: String) {
        guard ModuleDefinition.module(withID: id) != nil, enabled != isEnabled(id) else { return }
        if enabled {
            enabledModules.append(id)
        } else {
            enabledModules.removeAll { $0 == id }
        }
        save()
    }

    /// Reorders the shown modules, with `List.onMove` semantics.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard source.allSatisfy(enabledModules.indices.contains),
            (0...enabledModules.count).contains(destination)
        else { return }
        enabledModules.move(fromOffsets: source, toOffset: destination)
        save()
    }

    /// Swaps a module with the one above it ("Przesuń wyżej").
    func moveUp(_ id: String) {
        guard canMoveUp(id), let index = enabledModules.firstIndex(of: id) else { return }
        enabledModules.swapAt(index, index - 1)
        save()
    }

    /// Swaps a module with the one below it ("Przesuń niżej").
    func moveDown(_ id: String) {
        guard canMoveDown(id), let index = enabledModules.firstIndex(of: id) else { return }
        enabledModules.swapAt(index, index + 1)
        save()
    }

    /// Drag on Home: puts `id` where `target` is, shifting the modules in
    /// between by one. Dragging down lands below the target, dragging up lands
    /// above it.
    func move(_ id: String, onto target: String) {
        guard id != target,
            let from = enabledModules.firstIndex(of: id),
            let to = enabledModules.firstIndex(of: target)
        else { return }
        enabledModules.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        save()
    }

    // MARK: Persistence
    private func save() {
        defaults.set(enabledModules, forKey: DefaultsKey.enabledModules.rawValue)
    }
}
