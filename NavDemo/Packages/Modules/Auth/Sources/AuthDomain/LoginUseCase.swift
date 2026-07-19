public protocol LoginUseCase: Sendable {
    func execute(email: String, password: String) async throws -> User
}

public struct LoginUseCaseImpl: LoginUseCase {
    private let repository: UserRepository
    public init(repository: UserRepository) { self.repository = repository }

    public func execute(email: String, password: String) async throws -> User {
        guard email.contains("@"), email.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.invalidCredentials }
        return try await repository.login(email: email, password: password)
    }
}
