import SwiftUI
import DIContainer
import Navigation
import CoreNetworking
import AuthPublicAPI
import HomePublicAPI
import PaymentsPublicAPI

/// The single file in the entire codebase that imports every module's
/// PublicAPI together.
struct RootView: View {
    @StateObject var router = AppRouter()
    let container: DIContainer

    private let deepLinkParsers: [DeepLinkParser] = [
        AuthDeepLinkParser(), HomeDeepLinkParser(), PaymentsDeepLinkParser()
    ]

    #if !PRODUCTION
    @State private var showingEnvironmentSwitcher = false
    #endif

    var body: some View {
        NavigationStack(path: $router.path) {
            AuthModule.makeView(
                for: .login,
                container: container,
                router: AuthRoutingAdapter(appRouter: router)
            )
            // ONE registration for every module's routes, not one per
            // module. This works because AppRouter.navigate wraps every
            // pushed value in AnyHashable before appending — see the
            // comment there for why. The cost of this simplification is
            // documented on buildAny(_:) below.
            .navigationDestination(for: AnyHashable.self) { erasedRoute in
                buildAny(erasedRoute)
            }
            #if !PRODUCTION
            // Debug-only entry point to the runtime environment switcher —
            // compiled OUT of Prod builds entirely via the PRODUCTION flag
            // set in Config/Prod.xcconfig, not just hidden behind a toggle.
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEnvironmentSwitcher = true
                    } label: {
                        if let provider = container.resolve(EnvironmentProvider.self) {
                            Text(provider.current.rawValue.uppercased())
                                .font(.caption.bold())
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEnvironmentSwitcher) {
                if let provider = container.resolve(EnvironmentProvider.self) {
                    EnvironmentSwitcherView(provider: provider)
                        .presentationDetents([.height(160)])
                }
            }
            #endif
        }
        .sheet(item: $router.presentedSheet) { wrapped in buildAny(wrapped.value) }
        .fullScreenCover(item: $router.presentedFullScreen) { wrapped in buildAny(wrapped.value) }
        .onOpenURL { url in
            for parser in deepLinkParsers {
                if let (route, presentation) = parser.parse(url: url) {
                    router.navigate(to: route, presentation: presentation)
                    break
                }
            }
        }
    }
}
