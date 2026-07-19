import PaymentsPresentation
import PaymentsPublicAPI
import Navigation

@MainActor
final class PaymentsRoutingAdapter: PaymentsRouting {
    private let appRouter: Router
    init(appRouter: Router) { self.appRouter = appRouter }

    func navigateToHistory() {
        appRouter.navigate(to: PaymentsRoute.history, presentation: .push)
    }
    func dismiss() {
        appRouter.dismiss()
    }
}
