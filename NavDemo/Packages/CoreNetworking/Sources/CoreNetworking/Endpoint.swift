import Foundation

public struct Endpoint: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let body: Data?
    /// Whether AuthTokenInterceptor should attach a bearer token. Set
    /// false for e.g. a login/signup call that has no token yet.
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
    }

    /// Convenience for the common case: encode a Codable body as JSON.
    ///
    ///     let endpoint = try Endpoint.json(path: "/auth/login", body: LoginRequest(email: e, password: p))
    public static func json<Body: Encodable>(
        path: String,
        method: HTTPMethod = .post,
        body: Body,
        requiresAuth: Bool = true,
        encoder: JSONEncoder = Endpoint.defaultEncoder
    ) throws -> Endpoint {
        let data = try encoder.encode(body)
        return Endpoint(
            path: path,
            method: method,
            headers: ["Content-Type": "application/json"],
            body: data,
            requiresAuth: requiresAuth
        )
    }

    public static var defaultEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
