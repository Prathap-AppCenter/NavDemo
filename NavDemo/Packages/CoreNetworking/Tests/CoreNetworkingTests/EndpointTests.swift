import XCTest
@testable import CoreNetworking

final class EndpointTests: XCTestCase {
    struct LoginRequest: Encodable { let email: String }

    func test_jsonEndpoint_setsContentTypeAndBody() throws {
        let endpoint = try Endpoint.json(path: "/auth/login", body: LoginRequest(email: "a@b.com"))
        XCTAssertEqual(endpoint.headers["Content-Type"], "application/json")
        XCTAssertNotNil(endpoint.body)
        XCTAssertEqual(endpoint.method, .post)
    }

    func test_defaultInit_requiresAuthByDefault() {
        let endpoint = Endpoint(path: "/items")
        XCTAssertTrue(endpoint.requiresAuth)
    }
}
