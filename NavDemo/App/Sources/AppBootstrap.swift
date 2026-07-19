import DIContainer
import CoreNetworking
import AuthPublicAPI
import HomePublicAPI
import PaymentsPublicAPI

/// The App target is the ONLY place in the codebase that imports every
/// module's PublicAPI together. This is intentional and is what breaks
/// the circular-dependency problem: the arrow only ever points
/// App -> Module, never Module -> App.
enum AppBootstrap {
    static func run() -> DIContainer {
        let container = DIContainer.shared

        // Register shared services once, here, at the top of the app.
        container.register(NetworkClient.self, instance: MockNetworkClient())

        let modules: [ModuleDependency.Type] = [AuthModule.self, HomeModule.self, PaymentsModule.self]
        for module in modules {
            do {
                try DependencyValidator.validate(module, in: container)
            } catch {
                #if DEBUG
                fatalError("\(error)")
                #else
                print("[Bootstrap] \(error)")
                #endif
            }
        }
        return container
    }
}
