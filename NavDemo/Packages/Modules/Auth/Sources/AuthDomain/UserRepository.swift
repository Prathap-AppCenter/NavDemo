public protocol UserRepository: Sendable {
    func login(email: String, password: String) async throws -> User
    func signup(email: String, password: String, name: String) async throws -> User
    func currentUser() async -> User?
}
