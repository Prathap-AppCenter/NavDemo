import SwiftUI

public struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    public init(viewModel: @autoclosure @escaping () -> LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Log In").font(.largeTitle.bold())

            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("login.email")

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("login.password")

            if case .error(let message) = viewModel.state {
                Text(message).foregroundColor(.red).font(.footnote)
            }

            Button {
                viewModel.onLoginTapped()
            } label: {
                if viewModel.state == .loading {
                    ProgressView()
                } else {
                    Text("Log In").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("login.submit")

            Button("Forgot password?") { viewModel.onForgotPasswordTapped() }
            Button("Create an account") { viewModel.onSignupTapped() }
        }
        .padding()
    }
}
