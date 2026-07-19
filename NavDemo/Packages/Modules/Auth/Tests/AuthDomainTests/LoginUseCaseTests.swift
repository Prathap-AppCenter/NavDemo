import XCTest
@testable import AuthDomain

final class FakeRepo: UserRepository {
    func login(email: String, password: String) async throws -> User { User(id: "1", email: email, name: "X") }
    func signup(email: String, password: String, name: String) async throws -> User { User(id: "1", email: email, name: name) }
    func currentUser() async -> User? { nil }
}

final class LoginUseCaseTests: XCTestCase {
    func test_invalidEmail_throws() async {
        let useCase = LoginUseCaseImpl(repository: FakeRepo())
        do {
            _ = try await useCase.execute(email: "not-an-email", password: "123456")
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidEmail)
        }
    }

    func test_validCredentials_returnsUser() async throws {
        let useCase = LoginUseCaseImpl(repository: FakeRepo())
        let user = try await useCase.execute(email: "a@b.com", password: "123456")
        XCTAssertEqual(user.email, "a@b.com")
    }
}
