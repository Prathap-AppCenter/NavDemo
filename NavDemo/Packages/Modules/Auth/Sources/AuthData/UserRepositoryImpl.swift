import Foundation
import AuthDomain
import CoreNetworking

public final class UserRepositoryImpl: UserRepository {
    private let network: NetworkClient
    public init(network: NetworkClient) { self.network = network }

    public func login(email: String, password: String) async throws -> User {
        do {
            // Login has no token yet, so requiresAuth: false — AuthTokenInterceptor
            // will skip attaching a bearer header for this call.
            let endpoint = Endpoint(
                path: "/auth/login",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: try JSONEncoder().encode(["email": email, "password": password]),
                requiresAuth: false
            )
            let dto = try await network.send(endpoint, as: UserDTO.self)
            return dto.toDomain()
        } catch NetworkError.statusCode(401, data: _) {
            throw AuthError.invalidCredentials
        } catch {
            throw AuthError.network("\(error)")
        }
    }

    public func signup(email: String, password: String, name: String) async throws -> User {
        let endpoint = Endpoint(
            path: "/auth/signup",
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: try JSONEncoder().encode(["email": email, "password": password, "name": name]),
            requiresAuth: false
        )
        let dto = try await network.send(endpoint, as: UserDTO.self)
        return dto.toDomain()
    }

    public func currentUser() async -> User? { nil }
}
