import SwiftUI

public struct CheckoutView: View {
    let orderId: String
    let router: PaymentsRouting

    public init(orderId: String, router: PaymentsRouting) {
        self.orderId = orderId
        self.router = router
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Checkout").font(.largeTitle.bold())
            Text("Order: \(orderId)").foregroundColor(.secondary)
            Button("Close") { router.dismiss() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("checkout.close")
        }
        .padding()
    }
}

public struct HistoryView: View {
    public init() {}
    public var body: some View { Text("Payment history (stub)") }
}
