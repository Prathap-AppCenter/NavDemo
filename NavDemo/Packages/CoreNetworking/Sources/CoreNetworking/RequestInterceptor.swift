import Foundation

/// A hook into every request/response that goes through DefaultNetworkClient.
/// Compose whatever behaviors you need (auth, logging, analytics timing,
/// retry-triggering headers) as separate small interceptors rather than
/// building one giant network client.
public protocol RequestInterceptor: Sendable {
    /// Mutate/inspect the request before it's sent — e.g. add a header.
    func adapt(_ request: URLRequest, endpoint: Endpoint) async throws -> URLRequest

    /// Observe the outcome after the fact — e.g. logging. Not able to
    /// mutate anything; purely observational.
    func didReceive(response: URLResponse?, data: Data?, error: Error?, for endpoint: Endpoint)
}

public extension RequestInterceptor {
    func didReceive(response: URLResponse?, data: Data?, error: Error?, for endpoint: Endpoint) {}
}
