import Foundation

public final class DIContainer: @unchecked Sendable {
    public static let shared = DIContainer()

    private var services: [ObjectIdentifier: Any] = [:]
    private let lock = NSRecursiveLock()

    public init() {}

    public func register<T>(_ type: T.Type, instance: T) {
        lock.lock(); defer { lock.unlock() }
        services[ObjectIdentifier(type)] = instance
    }

    public func resolve<T>(_ type: T.Type = T.self) -> T? {
        lock.lock(); defer { lock.unlock() }
        return services[ObjectIdentifier(type)] as? T
    }

    public func hasRegistration(for type: Any.Type) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return services[ObjectIdentifier(type)] != nil
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        services.removeAll()
    }
}
