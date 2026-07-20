import Foundation
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

        // The environment this LAUNCH starts on: read from Info.plist,
        // which Xcode fills in from whichever scheme's .xcconfig was
        // active at build time (see project.yml -> configFiles, and
        // Config/*.xcconfig). Falls back to .prod if the key is ever
        // missing — fail SAFE, never silently ship pointed at dev.
        let environmentProvider = DefaultEnvironmentProvider(buildDefault: readBuildEnvironment())

        let networkClient = DefaultNetworkClient(
            environmentProvider: environmentProvider,
            interceptors: [
                LoggingInterceptor(environmentProvider: environmentProvider)
                // Add AuthTokenInterceptor(tokenProvider:) here once a real
                // TokenProvider (backed by Keychain) exists.
            ]
        )

        container.register(EnvironmentProvider.self, instance: environmentProvider)
        container.register(NetworkClient.self, instance: networkClient)

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

    private static func readBuildEnvironment() -> APIEnvironment {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "APIEnvironment") as? String,
            let environment = APIEnvironment(rawValue: raw)
        else {
            return .prod
        }
        return environment
    }
}
