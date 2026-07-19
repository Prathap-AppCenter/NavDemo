import Foundation
import AuthDomain
import CoreNetworking

public final class UserRepositoryImpl: UserRepository {
    private let network: NetworkClient
    public init(network: NetworkClient) { self.network = network }

    public func login(email: String, password: String) async throws -> User {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        let endpoint = Endpoint(path: "/auth/login", method: "POST",
                                 headers: ["Content-Type": "application/json"], body: body)
        do {
            let dto = try await network.send(endpoint, as: UserDTO.self)
            return dto.toDomain()
        } catch NetworkError.statusCode(401) {
            throw AuthError.invalidCredentials
        } catch {
            throw AuthError.network("\(error)")
        }
    }

    public func signup(email: String, password: String, name: String) async throws -> User {
        let body = try JSONEncoder().encode(["email": email, "password": password, "name": name])
        let endpoint = Endpoint(path: "/auth/signup", method: "POST",
                                 headers: ["Content-Type": "application/json"], body: body)
        let dto = try await network.send(endpoint, as: UserDTO.self)
        return dto.toDomain()
    }

    public func currentUser() async -> User? { nil }
}
