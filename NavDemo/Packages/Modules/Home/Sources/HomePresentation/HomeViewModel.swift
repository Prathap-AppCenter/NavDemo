import Foundation
import HomeDomain

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var items: [Item] = []
    @Published public private(set) var isLoading = false

    private let repository: ItemRepository
    private weak var router: HomeRouting?

    public init(repository: ItemRepository, router: HomeRouting) {
        self.repository = repository
        self.router = router
    }

    public func onAppear() {
        guard items.isEmpty else { return }
        isLoading = true
        Task {
            items = (try? await repository.fetchItems()) ?? []
            isLoading = false
        }
    }

    public func onItemTapped(_ item: Item) {
        router?.navigateToItemDetail(itemId: item.id)
    }

    public func onCheckoutTapped() {
        router?.navigateToPaymentsCheckout(orderId: "order-\(UUID().uuidString.prefix(6))")
    }
}
