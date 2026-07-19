import Foundation

/// Verbose request/response logging — automatically OFF in prod via
/// `APIEnvironment.allowsVerboseLogging`, so there's no separate
/// "did someone forget to strip logging before shipping" step.
public struct LoggingInterceptor: RequestInterceptor {
    private let environmentProvider: EnvironmentProvider

    public init(environmentProvider: EnvironmentProvider) {
        self.environmentProvider = environmentProvider
    }

    public func adapt(_ request: URLRequest, endpoint: Endpoint) async throws -> URLRequest {
        if environmentProvider.current.allowsVerboseLogging {
            let url = request.url?.absoluteString ?? "?"
            print("➡️ [\(environmentProvider.current.rawValue.uppercased())] \(endpoint.method.rawValue) \(url)")
        }
        return request
    }

    public func didReceive(response: URLResponse?, data: Data?, error: Error?, for endpoint: Endpoint) {
        guard environmentProvider.current.allowsVerboseLogging else { return }
        if let http = response as? HTTPURLResponse {
            print("⬅️ [\(http.statusCode)] \(endpoint.path)")
        }
        if let error {
            print("❌ \(endpoint.path) failed: \(error)")
        }
    }
}
