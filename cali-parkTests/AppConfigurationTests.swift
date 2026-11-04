import Foundation
import Testing
import UIKit

@testable import cali_park

/// The built app's Info.plist (unit tests run inside the app, so
/// `Bundle.main` is the app bundle).
struct AppConfigurationTests {
    /// E-15/G-24: the app is dark only, and its launch screen is the app's
    /// background colour rather than a white flash.
    @Test
    func theAppIsDarkFromTheLaunchScreenOn() throws {
        #expect(Bundle.main.object(forInfoDictionaryKey: "UIUserInterfaceStyle") as? String == "Dark")

        let launchScreen = try #require(Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen") as? [String: Any])
        let colorName = try #require(launchScreen["UIColorName"] as? String)
        #expect(UIColor(named: colorName) != nil)
    }

    /// G-24: no export compliance question on every upload.
    @Test
    func declaresNoNonExemptEncryption() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "ITSAppUsesNonExemptEncryption") as? Bool == false)
    }
}
