public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    /// GET is safe to auto-retry on a transient server error; the others
    /// generally aren't (you don't want to auto-retry a POST that might
    /// have partially succeeded server-side).
    var isSafeToRetry: Bool { self == .get }
}
