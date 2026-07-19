import XCTest
@testable import AuthPresentation
import AuthDomain

final class FakeLoginUseCase: LoginUseCase {
    var result: Result<User, Error>
    init(result: Result<User, Error>) { self.result = result }
    func execute(email: String, password: String) async throws -> User { try result.get() }
}

@MainActor
final class FakeAuthRouter: AuthRouting {
    var didNavigateToHome = false
    var didNavigateToSignup = false
    func navigateToHome() { didNavigateToHome = true }
    func navigateToSignup() { didNavigateToSignup = true }
    func navigateToForgotPassword() {}
    func dismiss() {}
}

@MainActor
final class LoginViewModelTests: XCTestCase {
    func test_successfulLogin_navigatesToHome() async {
        let router = FakeAuthRouter()
        let vm = LoginViewModel(
            loginUseCase: FakeLoginUseCase(result: .success(User(id: "1", email: "a@b.com", name: "A"))),
            router: router
        )
        vm.email = "a@b.com"; vm.password = "123456"

        vm.onLoginTapped()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(router.didNavigateToHome)
    }

    func test_failedLogin_setsErrorState() async {
        let router = FakeAuthRouter()
        let vm = LoginViewModel(
            loginUseCase: FakeLoginUseCase(result: .failure(AuthError.invalidCredentials)),
            router: router
        )
        vm.email = "a@b.com"; vm.password = "123456"

        vm.onLoginTapped()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.state, .error("Incorrect email or password."))
        XCTAssertFalse(router.didNavigateToHome)
    }
}
