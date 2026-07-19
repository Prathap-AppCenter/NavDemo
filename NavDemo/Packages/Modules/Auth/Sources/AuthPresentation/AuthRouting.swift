/// Auth OWNS this protocol. It has zero knowledge of AppRoute, Home,
/// Payments, or the App target. The App target supplies a concrete
/// implementation of this from outside (see App/Sources/Routing).
public protocol AuthRouting: AnyObject {
    func navigateToHome()
    func navigateToSignup()
    func navigateToForgotPassword()
    func dismiss()
}
