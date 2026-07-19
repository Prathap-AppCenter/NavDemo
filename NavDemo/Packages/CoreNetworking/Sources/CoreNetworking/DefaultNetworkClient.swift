import Foundation

/// The real, URLSession-backed implementation. Everything environment-
/// specific (base URL, timeout, headers, logging verbosity) is read from
/// `environmentProvider.current` fresh on EVERY request — so flipping
/// environments at runtime (see EnvironmentSwitcherView) takes effect on
/// the very next call, with no need to rebuild or re-register this client.
public final class DefaultNetworkClient: NetworkClient, @unchecked Sendable {
    private let environmentProvider: EnvironmentProvider
    private let session: URLSession
    private let interceptors: [RequestInterceptor]
    private let decoder: JSONDecoder
    private let maxRetries: Int

    public init(
        environmentProvider: EnvironmentProvider,
        session: URLSession = .shared,
        interceptors: [RequestInterceptor] = [],
        decoder: JSONDecoder = DefaultNetworkClient.defaultDecoder(),
        maxRetries: Int = 1
    ) {
        self.environmentProvider = environmentProvider
        self.session = session
        self.interceptors = interceptors
        self.decoder = decoder
        self.maxRetries = maxRetries
    }

    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try await sendRaw(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding("\(error)")
        }
    }

    public func send(_ endpoint: Endpoint) async throws {
        _ = try await sendRaw(endpoint)
    }

    // MARK: - Core request pipeline

    private func sendRaw(_ endpoint: Endpoint, attempt: Int = 0) async throws -> Data {
        let environment = environmentProvider.current

        guard var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: environment.requestTimeout)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        // Environment-wide headers first, endpoint-specific headers can override them.
        environment.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        for interceptor in interceptors {
            request = try await interceptor.adapt(request, endpoint: endpoint)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.underlying("No HTTP response received")
            }

            interceptors.forEach { $0.didReceive(response: response, data: data, error: nil, for: endpoint) }

            switch http.statusCode {
            case 200..<300:
                return data

            case 401:
                throw NetworkError.unauthorized

            case 403:
                throw NetworkError.forbidden

            case 404:
                throw NetworkError.notFound

            case 500..<600 where attempt < maxRetries && endpoint.method.isSafeToRetry:
                // Exponential backoff: 0.5s, 1s, 2s, ... Only retries GET
                // requests — see HTTPMethod.isSafeToRetry.
                let delayNanoseconds = UInt64(pow(2.0, Double(attempt)) * 500_000_000)
                try await Task.sleep(nanoseconds: delayNanoseconds)
                return try await sendRaw(endpoint, attempt: attempt + 1)

            default:
                throw NetworkError.statusCode(http.statusCode, data: data)
            }
        } catch let error as NetworkError {
            interceptors.forEach { $0.didReceive(response: nil, data: nil, error: error, for: endpoint) }
            throw error
        } catch {
            interceptors.forEach { $0.didReceive(response: nil, data: nil, error: error, for: endpoint) }
            let nsError = error as NSError
            if nsError.code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            }
            if nsError.code == NSURLErrorNotConnectedToInternet {
                throw NetworkError.noConnectivity
            }
            throw NetworkError.underlying("\(error)")
        }
    }
}
