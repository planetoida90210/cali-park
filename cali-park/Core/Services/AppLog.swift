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

// MARK: - StoreLoadFailure
/// A store that threw on load: saved training data exists but cannot be read.
/// The store kept the file (and refuses to write over it), so the alert copy
/// can promise nothing was deleted. Services expose this instead of an empty
/// value, so a broken file never reads as an empty journal.
nonisolated struct StoreLoadFailure: Error, Equatable, Sendable {
    /// Shared alert copy for every screen whose data failed to load.
    static let message = "Nie udało się odczytać zapisanych treningów. Twoje dane nie zostały usunięte."

    /// The underlying error, for the logs.
    let reason: String

    init(_ error: any Error) {
        reason = String(describing: error)
    }

    var message: String { Self.message }
}
