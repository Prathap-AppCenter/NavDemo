import XCTest
@testable import CoreNetworking

final class DefaultNetworkClientTests: XCTestCase {
    struct Item: Decodable, Equatable { let id: String; let title: String }

    func test_successfulResponse_decodesBody() async throws {
        let json = #"{"id":"1","title":"Headphones"}"#.data(using: .utf8)!
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }
        let client = DefaultNetworkClient(
            environmentProvider: FixedEnvironmentProvider(.dev),
            session: StubURLProtocol.makeSession()
        )
        let item = try await client.send(Endpoint(path: "/items/1"), as: Item.self)
        XCTAssertEqual(item, Item(id: "1", title: "Headphones"))
    }

    func test_404_throwsNotFound() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let client = DefaultNetworkClient(
            environmentProvider: FixedEnvironmentProvider(.dev),
            session: StubURLProtocol.makeSession()
        )
        do {
            _ = try await client.send(Endpoint(path: "/missing"), as: Item.self)
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? NetworkError, .notFound)
        }
    }

    func test_401_throwsUnauthorized() async {
        StubURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data())
        }
        let client = DefaultNetworkClient(
            environmentProvider: FixedEnvironmentProvider(.dev),
            session: StubURLProtocol.makeSession()
        )
        do {
            _ = try await client.send(Endpoint(path: "/secure"), as: Item.self)
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unauthorized)
        }
    }

    func test_requestGoesToCurrentEnvironmentsBaseURL() async throws {
        var capturedURL: URL?
        StubURLProtocol.handler = { request in
            capturedURL = request.url
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("{}".utf8))
        }
        let provider = FixedEnvironmentProvider(.qa)
        let client = DefaultNetworkClient(environmentProvider: provider, session: StubURLProtocol.makeSession())
        try await client.send(Endpoint(path: "/ping"))

        XCTAssertEqual(capturedURL?.host, APIEnvironment.qa.baseURL.host)
    }

    func test_switchingEnvironmentAtRuntime_affectsNextRequest() async throws {
        var capturedHosts: [String] = []
        StubURLProtocol.handler = { request in
            capturedHosts.append(request.url!.host!)
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("{}".utf8))
        }
        let provider = FixedEnvironmentProvider(.dev)
        let client = DefaultNetworkClient(environmentProvider: provider, session: StubURLProtocol.makeSession())

        try await client.send(Endpoint(path: "/ping"))
        provider.current = .prod   // simulate the debug switcher flipping environments
        try await client.send(Endpoint(path: "/ping"))

        XCTAssertEqual(capturedHosts, [APIEnvironment.dev.baseURL.host!, APIEnvironment.prod.baseURL.host!])
    }

    func test_authInterceptor_attachesBearerTokenOnlyWhenRequired() async throws {
        struct FakeTokenProvider: TokenProvider {
            func currentToken() async -> String? { "abc123" }
        }

        var lastCapturedAuthHeader: String?
        StubURLProtocol.handler = { request in
            lastCapturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("{}".utf8))
        }
        let client = DefaultNetworkClient(
            environmentProvider: FixedEnvironmentProvider(.dev),
            session: StubURLProtocol.makeSession(),
            interceptors: [AuthTokenInterceptor(tokenProvider: FakeTokenProvider())]
        )

        try await client.send(Endpoint(path: "/secure", requiresAuth: true))
        XCTAssertEqual(lastCapturedAuthHeader, "Bearer abc123")

        lastCapturedAuthHeader = nil
        try await client.send(Endpoint(path: "/public", requiresAuth: false))
        XCTAssertNil(lastCapturedAuthHeader)
    }
}
