import Foundation

/// The app-level navigation contract. Deliberately generic over Route —
/// there is no shared "AppRoute" enum anymore. Each module owns its own
/// Route type (e.g. AuthRoute, HomeRoute) and pushes/presents it directly.
/// This is what lets a module add a new screen by touching only its own
/// package — no shared file changes, no merge-conflict surface.
@MainActor
public protocol Router: AnyObject {
    func navigate<Route: Hashable>(to route: Route, presentation: Presentation)
    func pop()
    func popToRoot()
    func dismiss()
}
