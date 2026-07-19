import SwiftUI
import DIContainer
import CoreNetworking
import AuthPublicAPI

/// Run this target directly (select "AuthDemoApp" scheme in Xcode) to
/// build and preview ONLY the Auth module — no other module in the
/// monorepo needs to compile for this to work.
@main
struct AuthDemoApp: App {
    init() {
        // Register whatever real Auth needs. In the real app this
        // registration happens once in AppBootstrap; here the Auth team
        // owns their own minimal bootstrap for local development.
        DIContainer.shared.register(NetworkClient.self, instance: MockNetworkClient())
    }

    var body: some Scene {
        WindowGroup {
            AuthModule.makeView(for: .login, container: .shared, router: DemoAuthRouter())
        }
    }
}
