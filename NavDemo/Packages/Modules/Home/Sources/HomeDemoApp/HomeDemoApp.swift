import SwiftUI
import DIContainer
import CoreNetworking
import HomePublicAPI

/// Select the "HomeDemoApp" scheme to build and run just Home — Auth and
/// Payments never need to be checked out or compiled for this.
///
/// Home genuinely needs a NetworkClient (see HomeModule.requiredDependencies
/// in HomePublicAPI). Because the real App target isn't involved here, THIS
/// file is responsible for registering a stand-in for every dependency Home
/// declares — mirroring, in miniature, what AppBootstrap does for the whole
/// app. If you forget one, DependencyValidator throws before any screen
/// renders, exactly like it would in the real app.
@main
struct HomeDemoApp: App {
    let bootstrapError: String?

    init() {
        let container = DIContainer.shared

        // Register a stand-in for every dependency HomeModule declares.
        // A real backend isn't needed for local UI work — MockNetworkClient
        // is enough to exercise the loading/empty/error states.
        container.register(NetworkClient.self, instance: MockNetworkClient())

        do {
            try DependencyValidator.validate(HomeModule.self, in: container)
            bootstrapError = nil
        } catch {
            // Deliberately NOT a fatalError here: this demo app's whole
            // point is fast local iteration, so surface the problem in
            // the UI instead of crashing the simulator on every launch.
            bootstrapError = "\(error)"
        }
    }

    var body: some Scene {
        WindowGroup {
            if let bootstrapError {
                DependencyErrorView(message: bootstrapError)
            } else {
                HomeModule.makeView(for: .root, container: .shared, router: DemoHomeRouter())
            }
        }
    }
}

/// Shown instead of crashing if HomeDemoApp forgot to register something
/// HomeModule.requiredDependencies asks for.
struct DependencyErrorView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Home demo app is missing a dependency")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
