import Foundation

/// Anything that can tell the network layer which environment to hit
/// RIGHT NOW. Kept as a protocol so DefaultNetworkClient never has to
/// change if you swap how environment selection works later (e.g. moving
/// from UserDefaults to a remote config service).
public protocol EnvironmentProvider: AnyObject, Sendable {
    var current: APIEnvironment { get set }
}

/// Reads/writes the selected environment from UserDefaults so a runtime
/// switch (see EnvironmentSwitcherView) survives an app relaunch — this is
/// what lets a QA tester flip from QA to UAT without a rebuild, and have
/// it stick.
///
/// `buildDefault` is what a FRESH INSTALL starts on — normally wired from
/// an Xcode build configuration (see Config/*.xcconfig in this package,
/// and AppBootstrap+Networking.swift for how that gets read at launch).
public final class DefaultEnvironmentProvider: EnvironmentProvider, @unchecked Sendable {
    private static let storageKey = "com.example.CoreNetworking.selectedEnvironment"

    private let userDefaults: UserDefaults
    private let lock = NSLock()
    private var _current: APIEnvironment

    public init(buildDefault: APIEnvironment, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let saved = userDefaults.string(forKey: Self.storageKey),
           let restored = APIEnvironment(rawValue: saved) {
            self._current = restored
        } else {
            self._current = buildDefault
        }
    }

    public var current: APIEnvironment {
        get {
            lock.lock(); defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock()
            _current = newValue
            lock.unlock()
            userDefaults.set(newValue.rawValue, forKey: Self.storageKey)
        }
    }
}

/// Use this in unit tests and module demo apps — a fixed environment,
/// no UserDefaults side effects.
public final class FixedEnvironmentProvider: EnvironmentProvider, @unchecked Sendable {
    public var current: APIEnvironment
    public init(_ environment: APIEnvironment) { self.current = environment }
}
