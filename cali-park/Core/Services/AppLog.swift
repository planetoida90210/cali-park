import Foundation
import os

// MARK: - AppLog
/// Factory for the app's `os.Logger`s: one subsystem (the bundle identifier),
/// one category per component.
nonisolated enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "cali-park"

    static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
