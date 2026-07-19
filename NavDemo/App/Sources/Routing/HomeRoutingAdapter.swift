import HomePresentation
import HomePublicAPI
import PaymentsPublicAPI   // needed for PaymentsRoute — Home requesting checkout
import Navigation

@MainActor
final class HomeRoutingAdapter: HomeRouting {
    private let appRouter: Router
    init(appRouter: Router) { self.appRouter = appRouter }

    func navigateToItemDetail(itemId: String) {
        appRouter.navigate(to: HomeRoute.detail(itemId: itemId), presentation: .push)
    }
    func navigateToPaymentsCheckout(orderId: String) {
        appRouter.navigate(to: PaymentsRoute.checkout(orderId: orderId), presentation: .sheet)
    }
    func navigateToProfile() {
        // wire up when a Profile module exists
    }
}
