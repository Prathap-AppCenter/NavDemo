import Foundation

public enum NetworkError: Error, Sendable {
    case invalidURL
    case noConnectivity
    case timeout
    case unauthorized                       // 401
    case forbidden                          // 403
    case notFound                           // 404
    case statusCode(Int, data: Data?)       // any other non-2xx
    case decoding(String)
    case underlying(String)
}

extension NetworkError: Equatable {
    // Data payloads aren't compared for equality — only the shape of the
    // error matters for tests and error-handling branches. Two
    // .statusCode(404, data: A) and .statusCode(404, data: B) should
    // still be considered "the same kind of failure."
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noConnectivity, .noConnectivity),
             (.timeout, .timeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound):
            return true
        case let (.statusCode(a, _), .statusCode(b, _)):
            return a == b
        case let (.decoding(a), .decoding(b)):
            return a == b
        case let (.underlying(a), .underlying(b)):
            return a == b
        default:
            return false
        }
    }
}
