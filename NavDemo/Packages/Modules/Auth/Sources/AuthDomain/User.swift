public struct User: Equatable, Sendable {
    public let id: String
    public let email: String
    public let name: String
    public init(id: String, email: String, name: String) {
        self.id = id; self.email = email; self.name = name
    }
}

public enum AuthError: Error, Equatable {
    case invalidEmail
    case invalidCredentials
    case network(String)
}
