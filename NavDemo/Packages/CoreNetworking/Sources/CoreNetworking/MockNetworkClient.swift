import Foundation

/// Drop-in stand-in for DefaultNetworkClient — used by module demo apps
/// (see the AuthDemoApp / HomeDemoApp pattern) and in unit tests, so
/// nothing ever needs a real backend to build or test.
public final class MockNetworkClient: NetworkClient, @unchecked Sendable {
    public var responseProvider: @Sendable (Endpoint) throws -> Data

    public init(responseProvider: @escaping @Sendable (Endpoint) throws -> Data = { _ in Data() }) {
        self.responseProvider = responseProvider
    }

    /// Convenience for the common case: always return one fixed Codable value.
    public static func returning<T: Encodable>(_ value: T, encoder: JSONEncoder = .init()) -> MockNetworkClient {
        MockNetworkClient { _ in try encoder.encode(value) }
    }

    public func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try responseProvider(endpoint)
        return try DefaultNetworkClient.defaultDecoder().decode(T.self, from: data)
    }

    public func send(_ endpoint: Endpoint) async throws {
        _ = try responseProvider(endpoint)
    }
}
