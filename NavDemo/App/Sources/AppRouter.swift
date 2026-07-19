import SwiftUI
import Navigation

/// A route stored generically so it can go into .sheet/.fullScreenCover
/// (which need a single concrete Identifiable type) and, since this
/// version of AppRouter, into pushes too — see the comment on `navigate`
/// below for why push now wraps in AnyHashable on purpose.
struct IdentifiableRoute: Identifiable {
    let value: AnyHashable
    var id: Int { value.hashValue }
}

/// The only place in the whole app where a real NavigationPath exists.
/// Notice: no reference to AuthRoute/HomeRoute/PaymentsRoute anywhere in
/// this file — it's generic, and stays correct as modules are added.
@MainActor
final class AppRouter: ObservableObject, Router {
    @Published var path = NavigationPath()
    @Published var presentedSheet: IdentifiableRoute?
    @Published var presentedFullScreen: IdentifiableRoute?

    func navigate<Route: Hashable>(to route: Route, presentation: Presentation) {
        switch presentation {
        case .push:
            // Deliberately wrap in AnyHashable before appending, rather
            // than `path.append(route)`. NavigationPath keys its
            // .navigationDestination(for:) lookup off the CONCRETE type
            // of the appended value — appending the raw Route would mean
            // a separate .navigationDestination(for: AuthRoute.self),
            // .navigationDestination(for: HomeRoute.self), etc. is needed
            // per module. Appending AnyHashable(route) instead means
            // every push shares one registered type (AnyHashable), so
            // RootView only needs ONE .navigationDestination call, no
            // matter how many modules exist. Trade-off: see RootView's
            // buildAny(_:) doc comment.
            path.append(AnyHashable(route))
        case .sheet:
            presentedSheet = IdentifiableRoute(value: AnyHashable(route))
        case .fullScreenCover:
            presentedFullScreen = IdentifiableRoute(value: AnyHashable(route))
        }
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }
    func popToRoot() {
        path.removeLast(path.count)
    }
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }
}
