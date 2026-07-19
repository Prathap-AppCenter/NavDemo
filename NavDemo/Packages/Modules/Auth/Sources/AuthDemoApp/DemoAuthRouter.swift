import AuthPresentation

/// Stand-in for the real AuthRoutingAdapter that normally lives in the
/// App target. The Auth team never needs the real Home or Payments module
/// to exist, build, or even be checked out to develop and click through
/// every Auth screen — this demo router just reports what WOULD happen.
final class DemoAuthRouter: AuthRouting {
    func navigateToHome() {
        print("[AuthDemo] would navigate to Home (owned by App target in the real app)")
    }
    func navigateToSignup() {
        print("[AuthDemo] navigating to Signup — this one IS real, it's Auth's own screen")
    }
    func navigateToForgotPassword() {
        print("[AuthDemo] navigating to Forgot Password — also Auth's own screen")
    }
    func dismiss() {
        print("[AuthDemo] dismiss")
    }
}
