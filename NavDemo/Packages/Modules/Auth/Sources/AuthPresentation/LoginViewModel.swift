import Foundation
import AuthDomain

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public private(set) var state: ViewState<User> = .idle

    private let loginUseCase: LoginUseCase
    private weak var router: AuthRouting?
    private var currentTask: Task<Void, Never>?

    public init(loginUseCase: LoginUseCase, router: AuthRouting) {
        self.loginUseCase = loginUseCase
        self.router = router
    }

    public func onLoginTapped() {
        currentTask?.cancel()
        state = .loading
        currentTask = Task { [weak self] in
            guard let self else { return }
            do {
                let user = try await self.loginUseCase.execute(email: self.email, password: self.password)
                guard !Task.isCancelled else { return }
                self.state = .loaded(user)
                self.router?.navigateToHome()
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .error(self.message(for: error))
            }
        }
    }

    public func onSignupTapped() { router?.navigateToSignup() }
    public func onForgotPasswordTapped() { router?.navigateToForgotPassword() }

    private func message(for error: Error) -> String {
        switch error as? AuthError {
        case .invalidEmail: return "Enter a valid email address."
        case .invalidCredentials: return "Incorrect email or password."
        case .network(let msg): return "Network error: \(msg)"
        case .none: return "Something went wrong."
        }
    }

    deinit { currentTask?.cancel() }
}
