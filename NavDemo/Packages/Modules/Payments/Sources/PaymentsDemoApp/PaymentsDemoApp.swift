import SwiftUI
import DIContainer
import PaymentsPublicAPI

@main
struct PaymentsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PaymentsModule.makeView(
                for: .checkout(orderId: "demo-123"),
                container: .shared,
                router: DemoPaymentsRouter()
            )
        }
    }
}
