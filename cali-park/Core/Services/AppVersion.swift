import Foundation

// MARK: - AppVersion
/// The marketing version and build number from the app's Info.plist, shown in
/// "O apce" and stamped into backup files.
nonisolated struct AppVersion: Equatable, Sendable {
    /// `CFBundleShortVersionString`, e.g. "1.0".
    let version: String
    /// `CFBundleVersion`, e.g. "5".
    let build: String

    /// "1.0 (5)".
    var text: String { "\(version) (\(build))" }

    init(version: String, build: String) {
        self.version = version
        self.build = build
    }

    init(bundle: Bundle) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    static let current = AppVersion(bundle: .main)
}
