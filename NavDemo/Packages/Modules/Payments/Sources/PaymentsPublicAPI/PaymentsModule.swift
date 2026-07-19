import SwiftUI
import DIContainer
import PaymentsPresentation

public enum PaymentsModule: ModuleDependency {
    public static var requiredDependencies: [Any.Type] { [] }

    @MainActor
    @ViewBuilder
    public static func makeView(for route: PaymentsRoute, container: DIContainer, router: PaymentsRouting) -> some View {
        switch route {
        case .checkout(let orderId):
            CheckoutView(orderId: orderId, router: router)
        case .history:
            HistoryView()
        case .cardDetails:
            Text("Card details (stub)")
        }
    }
}
