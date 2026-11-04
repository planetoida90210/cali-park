import Foundation

// MARK: - DefaultsKey
/// Every `UserDefaults` / `@AppStorage` key the app uses, in one place, so a
/// typo can't silently split state between two screens. The raw values are
/// the strings already stored on devices: never rename one.
///
/// `ModulePreferences` (Home modules) still keeps its own `"enabledModules"`
/// key until that type is rewritten.
enum DefaultsKey: String, CaseIterable {
    /// The first-run flow finished; gates `OnboardingView` vs `MainTabView`.
    case hasCompletedOnboarding
    /// The SetPad swipe hint was dismissed by the first set change.
    case hasSeenSetPadHint
    /// The leftover files of the removed Core Data scaffold were deleted.
    case didRemoveCoreDataScaffold
}
