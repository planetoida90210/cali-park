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

    /// G-11: iPhone only, portrait only, and the name under the icon.
    @Test
    func theAppIsAPortraitIPhoneApp() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "UIDeviceFamily") as? [Int] == [1])
        let orientations = Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations~iphone") as? [String]
        #expect(orientations == ["UIInterfaceOrientationPortrait"])
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String == "CaliPark")
    }

    /// G-6: the Parks map asks for location while in use, and says why.
    @Test
    func explainsTheLocationPrompt() throws {
        let purpose = try #require(Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String)
        #expect(purpose.contains("Parki"))
        #expect(Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") == nil)
    }

    /// C-2/G-1: App Store Connect rejects an upload whose privacy manifest
    /// misses a required-reason API. The app reads `UserDefaults` (`CA92.1`);
    /// a Release archive references no other required-reason API
    /// (`docs/release/checklist.md`).
    @Test
    func shipsThePrivacyManifest() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let manifest = try #require(
            try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])

        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
        let accessed = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        var reasons: [String: [String]] = [:]
        for entry in accessed {
            let category = try #require(entry["NSPrivacyAccessedAPIType"] as? String)
            reasons[category] = entry["NSPrivacyAccessedAPITypeReasons"] as? [String]
        }
        #expect(reasons == ["NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"]])
    }
}
