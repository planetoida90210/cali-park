import Foundation
import Testing
@testable import cali_park

@Suite("The unit test host does not start the real app")
struct AppLaunchTests {
    @Test
    func thisProcessIsDetectedAsTheUnitTestHost() {
        #expect(AppLaunch.isHostingUnitTests(ProcessInfo.processInfo.environment))
    }

    @Test
    func aNormalLaunchStartsTheRealApp() {
        #expect(AppLaunch.isHostingUnitTests([:]) == false)
        #expect(AppLaunch.isHostingUnitTests(["SIMULATOR_DEVICE_NAME": "iPhone 17"]) == false)
    }
}
