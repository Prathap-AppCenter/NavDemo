import XCTest
@testable import CoreNetworking

final class EnvironmentProviderTests: XCTestCase {
    func test_freshInstall_usesBuildDefault() {
        let defaults = UserDefaults(suiteName: "EnvironmentProviderTests.\(UUID())")!
        let provider = DefaultEnvironmentProvider(buildDefault: .qa, userDefaults: defaults)
        XCTAssertEqual(provider.current, .qa)
    }

    func test_switchingEnvironment_persistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: "EnvironmentProviderTests.\(UUID())")!
        let first = DefaultEnvironmentProvider(buildDefault: .dev, userDefaults: defaults)
        first.current = .uat

        // Simulate an app relaunch: a NEW provider instance, same UserDefaults.
        let second = DefaultEnvironmentProvider(buildDefault: .dev, userDefaults: defaults)
        XCTAssertEqual(second.current, .uat)
    }

    func test_fixedProvider_neverPersists() {
        let provider = FixedEnvironmentProvider(.dev)
        XCTAssertEqual(provider.current, .dev)
        provider.current = .prod
        XCTAssertEqual(provider.current, .prod) // just an in-memory value, no persistence to verify
    }
}
