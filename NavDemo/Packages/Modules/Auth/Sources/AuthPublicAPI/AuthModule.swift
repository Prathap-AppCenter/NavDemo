import SwiftUI
import DIContainer
import CoreNetworking
import AuthDomain
import AuthData
import AuthPresentation

/// The ONLY thing other modules or the App target are allowed to import
/// from Auth. Everything else (Domain/Data/Presentation) is internal.
public enum AuthModule: ModuleDependency {
    public static var requiredDependencies: [Any.Type] {
        [NetworkClient.self]
    }

    @MainActor
    @ViewBuilder
    public static func makeView(for route: AuthRoute, container: DIContainer, router: AuthRouting) -> some View {
        let network = container.resolve(NetworkClient.self)!
        let repo = UserRepositoryImpl(network: network)

        switch route {
        case .login:
            LoginView(viewModel: LoginViewModel(loginUseCase: LoginUseCaseImpl(repository: repo), router: router))
        case .signup:
            SignupView()
        case .forgotPassword:
            ForgotPasswordView()
        }
    }
}
