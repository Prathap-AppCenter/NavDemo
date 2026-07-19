import HomePresentation

final class DemoHomeRouter: HomeRouting {
    func navigateToItemDetail(itemId: String) {
        print("[HomeDemo] would navigate to item detail: \(itemId)")
    }
    func navigateToPaymentsCheckout(orderId: String) {
        print("[HomeDemo] would navigate to Payments checkout (real Payments module not needed here): \(orderId)")
    }
    func navigateToProfile() {
        print("[HomeDemo] would navigate to Profile")
    }
}
