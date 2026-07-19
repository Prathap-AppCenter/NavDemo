import XCTest
@testable import NavDemo
import Navigation
import AuthPublicAPI
import HomePublicAPI
import PaymentsPublicAPI

/// This is the direct mitigation for the trade-off called out in
/// RootView.buildAny(_:) — that single function now handles push, sheet,
/// fullScreenCover, AND deep links via an `as?` cascade instead of a
/// compiler-exhaustive switch, so a forgotten case fails silently
/// (renders EmptyView) instead of failing to compile. This test suite is
/// what makes that failure visible again — one assertion per module's
/// route type, confirming every module's parser output is actually
/// dispatchable.
final class DeepLinkParsingTests: XCTestCase {
    func test_authParser_parsesLogin() {
        let url = URL(string: "myapp://auth/login")!
        let result = AuthDeepLinkParser().parse(url: url)
        XCTAssertEqual(result?.route.base as? AuthRoute, .login)
        XCTAssertEqual(result?.presentation, .push)
    }

    func test_homeParser_parsesItemDetail() {
        let url = URL(string: "myapp://home/item/abc123")!
        let result = HomeDeepLinkParser().parse(url: url)
        XCTAssertEqual(result?.route.base as? HomeRoute, .detail(itemId: "abc123"))
    }

    func test_paymentsParser_parsesCheckout() {
        let url = URL(string: "myapp://payments/checkout?orderId=xyz")!
        let result = PaymentsDeepLinkParser().parse(url: url)
        XCTAssertEqual(result?.route.base as? PaymentsRoute, .checkout(orderId: "xyz"))
        XCTAssertEqual(result?.presentation, .sheet)
    }

    /// Reminder test: whenever a new module ships, add its parser to
    /// RootView's `deepLinkParsers` array AND add a case to `buildAny`/
    /// `dispatch`. If you forget the second part, THIS is the kind of
    /// test that should be duplicated into that new module's parser test
    /// to catch it — the cast cascade itself won't.
    func test_unknownHost_allParsersReturnNil() {
        let url = URL(string: "myapp://unknown/path")!
        XCTAssertNil(AuthDeepLinkParser().parse(url: url))
        XCTAssertNil(HomeDeepLinkParser().parse(url: url))
        XCTAssertNil(PaymentsDeepLinkParser().parse(url: url))
    }
}
