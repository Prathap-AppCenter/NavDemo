import AuthPresentation
import AuthPublicAPI   // needed for AuthRoute — Auth's own route type
import HomePublicAPI    // needed for HomeRoute — this is "navigateToHome" leaving Auth's vocabulary
import Navigation

/// Lives in the App target, NOT inside the Auth module. Auth defines
/// `AuthRouting`; this class fulfills it by pushing/presenting the
/// concrete Route values directly — no shared "AppRoute" wrapper needed
/// anymore.
@MainActor
final class AuthRoutingAdapter: AuthRouting {
    private let appRouter: Router
    init(appRouter: Router) { self.appRouter = appRouter }

    func navigateToHome() {
        appRouter.popToRoot()
        appRouter.navigate(to: HomeRoute.root, presentation: .push)
    }
    func navigateToSignup() {
        appRouter.navigate(to: AuthRoute.signup, presentation: .push)
    }
    func navigateToForgotPassword() {
        appRouter.navigate(to: AuthRoute.forgotPassword, presentation: .push)
    }
    func dismiss() {
        appRouter.dismiss()
    }
}
