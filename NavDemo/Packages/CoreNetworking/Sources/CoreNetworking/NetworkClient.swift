import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL
    case statusCode(Int)
    case decoding(String)
    case underlying(String)
}

public struct Endpoint {
    public let path: String
    public let method: String
    public let headers: [String: String]
    public let body: Data?

    public init(path: String, method: String = "GET", headers: [String: String] = [:], body: Data? = nil) {
        self.path = path; self.method = method; self.headers = headers; self.body = body
    }
}

public protocol NetworkClient: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

/// Minimal mock client used by this sample project so it runs with no
/// backend. Swap for a real URLSession-backed client in a production app.
public final class MockNetworkClient: NetworkClient {
    public init() {}

    public func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        try await Task.sleep(nanoseconds: 400_000_000) // simulate latency
        throw NetworkError.underlying("MockNetworkClient has no canned response for \(endpoint.path). Replace with DefaultNetworkClient + a real backend.")
    }
}
