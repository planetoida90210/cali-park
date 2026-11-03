import Foundation
import os

// MARK: - AppLog
/// Factory for the app's `os.Logger`s: one subsystem (the bundle identifier),
/// one category per component.
enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "cali-park"

    static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}

// MARK: - StoreLoadFailure
/// Shared alert copy for view models whose store throws on load: saved
/// training data exists but cannot be read. The store kept the file (and
/// refuses to write over it), so the message can promise nothing was deleted.
enum StoreLoadFailure {
    static let message = "Nie udało się odczytać zapisanych treningów. Twoje dane nie zostały usunięte."
}
