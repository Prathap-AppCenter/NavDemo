/// Home OWNS this protocol. It has zero knowledge of AppRoute, Auth,
/// Payments, or the App target.
public protocol HomeRouting: AnyObject {
    func navigateToItemDetail(itemId: String)
    func navigateToPaymentsCheckout(orderId: String)
    func navigateToProfile()
}
