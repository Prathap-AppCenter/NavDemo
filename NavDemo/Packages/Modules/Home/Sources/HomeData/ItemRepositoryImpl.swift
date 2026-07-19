import HomeDomain
import CoreNetworking

/// Takes a real NetworkClient dependency, passed in from outside — same
/// pattern as AuthData's UserRepositoryImpl. Falls back to sample data
/// when the network call fails so this sample project runs with no
/// backend; swap the catch block out once a real API exists.
public final class ItemRepositoryImpl: ItemRepository {
    private let network: NetworkClient
    public init(network: NetworkClient) { self.network = network }

    public func fetchItems() async throws -> [Item] {
        do {
            return try await network.send(Endpoint(path: "/items"), as: [Item].self)
        } catch {
            return sampleItems()
        }
    }

    private func sampleItems() -> [Item] {
        [
            Item(id: "1", title: "Wireless Headphones"),
            Item(id: "2", title: "Mechanical Keyboard"),
            Item(id: "3", title: "Standing Desk")
        ]
    }
}
