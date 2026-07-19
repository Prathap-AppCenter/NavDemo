import XCTest
@testable import Navigation

final class RouterProtocolShapeTests: XCTestCase {
    // Compile-time smoke test: confirms a Router conformance can be built
    // generically without any concrete Route type baked into this package.
    func test_genericNavigateCompiles() {
        final class FakeRouter: Router {
            var lastPresentation: Presentation?
            func navigate<Route: Hashable>(to route: Route, presentation: Presentation) {
                lastPresentation = presentation
            }
            func pop() {}
            func popToRoot() {}
            func dismiss() {}
        }
        let router = FakeRouter()
        router.navigate(to: "any-hashable-route-works", presentation: .push)
        XCTAssertEqual(router.lastPresentation, .push)
    }
}
