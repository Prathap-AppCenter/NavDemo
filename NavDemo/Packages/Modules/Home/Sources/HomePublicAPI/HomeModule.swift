import SwiftUI
import DIContainer
import CoreNetworking
import HomeDomain
import HomeData
import HomePresentation

public enum HomeModule: ModuleDependency {
    /// Home genuinely needs a NetworkClient to fetch items. Declaring it
    /// here means whoever bootstraps this module — the real AppBootstrap,
    /// OR HomeDemoApp's own mini bootstrap — MUST register one before
    /// building a single Home screen, and gets a clear failure if they don't.
    public static var requiredDependencies: [Any.Type] {
        [NetworkClient.self]
    }

    @MainActor
    @ViewBuilder
    public static func makeView(for route: HomeRoute, container: DIContainer, router: HomeRouting) -> some View {
        switch route {
        case .root:
            let network = container.resolve(NetworkClient.self)!   // safe: validated at bootstrap
            HomeView(viewModel: HomeViewModel(repository: ItemRepositoryImpl(network: network), router: router))
        case .detail(let itemId):
            ItemDetailView(itemId: itemId)
        }
    }
}
