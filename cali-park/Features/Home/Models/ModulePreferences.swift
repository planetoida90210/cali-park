import Foundation
import Observation

// MARK: - ModulePreferences
/// Which Home modules are shown, and in what order. Created once in
/// `AppEnvironment` and passed explicitly to Home and the module selection
/// screen.
///
/// Stored in `UserDefaults` under `DefaultsKey.enabledModules` as an array of
/// `HomeModule` raw values in display order (the format every earlier build
/// wrote), so existing users keep their choices. Values of modules that no
/// longer exist (the retired leaderboard and feed) and duplicates are dropped
/// on load.
@MainActor
@Observable
final class ModulePreferences {
    /// What a fresh install shows, until the athlete changes anything.
    static let defaultModules: [HomeModule] = [.lastWorkout, .nextWorkout, .weeklyGoal, .nearestPark]

    /// The shown modules, in display order.
    private(set) var enabledModules: [HomeModule]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        guard let saved = defaults.stringArray(forKey: DefaultsKey.enabledModules.rawValue) else {
            // Nothing is written until the athlete changes something, so a
            // later change of the defaults still reaches untouched installs.
            enabledModules = Self.defaultModules
            return
        }
        var seen = Set<HomeModule>()
        let cleaned = saved.compactMap(HomeModule.init(rawValue:)).filter { seen.insert($0).inserted }
        enabledModules = cleaned
        if cleaned.map(\.rawValue) != saved { save() }
    }

    // MARK: Queries
    /// The hidden modules, in catalog order.
    var disabledModules: [HomeModule] {
        HomeModule.allCases.filter { !enabledModules.contains($0) }
    }

    func isEnabled(_ module: HomeModule) -> Bool {
        enabledModules.contains(module)
    }

    func canMoveUp(_ module: HomeModule) -> Bool {
        guard let index = enabledModules.firstIndex(of: module) else { return false }
        return index > 0
    }

    func canMoveDown(_ module: HomeModule) -> Bool {
        guard let index = enabledModules.firstIndex(of: module) else { return false }
        return index < enabledModules.count - 1
    }

    // MARK: Intentions
    /// Shows a module (at the end) or hides it.
    func setEnabled(_ enabled: Bool, for module: HomeModule) {
        guard enabled != isEnabled(module) else { return }
        if enabled {
            enabledModules.append(module)
        } else {
            enabledModules.removeAll { $0 == module }
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
    func moveUp(_ module: HomeModule) {
        guard canMoveUp(module), let index = enabledModules.firstIndex(of: module) else { return }
        enabledModules.swapAt(index, index - 1)
        save()
    }

    /// Swaps a module with the one below it ("Przesuń niżej").
    func moveDown(_ module: HomeModule) {
        guard canMoveDown(module), let index = enabledModules.firstIndex(of: module) else { return }
        enabledModules.swapAt(index, index + 1)
        save()
    }

    /// Drag on Home: puts `module` where `target` is, shifting the modules in
    /// between by one. Dragging down lands below the target, dragging up lands
    /// above it.
    func move(_ module: HomeModule, onto target: HomeModule) {
        guard module != target,
            let from = enabledModules.firstIndex(of: module),
            let to = enabledModules.firstIndex(of: target)
        else { return }
        enabledModules.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        save()
    }

    // MARK: Persistence
    private func save() {
        defaults.set(enabledModules.map(\.rawValue), forKey: DefaultsKey.enabledModules.rawValue)
    }
}
