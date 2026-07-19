public protocol NetworkClient: Sendable {
    /// Send a request and decode the response body as `T`.
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T

    /// Send a request with no response body expected (e.g. a 204).
    func send(_ endpoint: Endpoint) async throws
}
