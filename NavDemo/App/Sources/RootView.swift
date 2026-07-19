import SwiftUI
import DIContainer
import Navigation
import AuthPublicAPI
import HomePublicAPI
import PaymentsPublicAPI

/// The single file in the entire codebase that imports every module's
/// PublicAPI together.
struct RootView: View {
    @StateObject private var router = AppRouter()
    let container: DIContainer

    private let deepLinkParsers: [DeepLinkParser] = [
        AuthDeepLinkParser(), HomeDeepLinkParser(), PaymentsDeepLinkParser()
    ]

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

    /// The one place in the codebase that turns an erased route back into
    /// a real screen — used for push, sheet, fullScreenCover, AND deep
    /// links, all funneling through here now.
    ///
    /// TRADE-OFF, stated plainly: this is an `as?` cascade, not a
    /// compiler-exhaustive `switch`. Forgetting to add a new module's
    /// case here means a push/sheet to that module's routes silently
    /// renders EmptyView instead of failing to compile. This used to be
    /// true only for sheets/deep links; collapsing push into the same
    /// AnyHashable path means push now carries the same risk, in
    /// exchange for needing only ONE .navigationDestination registration
    /// no matter how many modules exist. Mitigation: adding a module
    /// already requires touching this file once anyway (to add its
    /// RoutingAdapter + here), so the risk is "forgot a line in a file
    /// you were already editing," not "forgot a file entirely" — and
    /// App/Tests/DeepLinkDispatchTests.swift exercises each module's
    /// route end to end.
    @ViewBuilder
    private func buildAny(_ route: AnyHashable) -> some View {
        if let r = route.base as? AuthRoute {
            AuthModule.makeView(for: r, container: container, router: AuthRoutingAdapter(appRouter: router))
        } else if let r = route.base as? HomeRoute {
            HomeModule.makeView(for: r, container: container, router: HomeRoutingAdapter(appRouter: router))
        } else if let r = route.base as? PaymentsRoute {
            PaymentsModule.makeView(for: r, container: container, router: PaymentsRoutingAdapter(appRouter: router))
        } else {
            EmptyView()
        }
    }
}
