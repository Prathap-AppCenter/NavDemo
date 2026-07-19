import Foundation

/// The auth module (or wherever tokens are stored) supplies a real
/// implementation of this; CoreNetworking never knows how a token is
/// obtained or stored, only how to ask for the current one.
public protocol TokenProvider: Sendable {
    func currentToken() async -> String?
}

/// Attaches `Authorization: Bearer <token>` to any endpoint that opted in
/// via `Endpoint.requiresAuth`. A login/signup endpoint would set
/// `requiresAuth: false` and skip this entirely.
public struct AuthTokenInterceptor: RequestInterceptor {
    private let tokenProvider: TokenProvider

    public init(tokenProvider: TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    public func adapt(_ request: URLRequest, endpoint: Endpoint) async throws -> URLRequest {
        guard endpoint.requiresAuth, let token = await tokenProvider.currentToken() else {
            return request
        }
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
