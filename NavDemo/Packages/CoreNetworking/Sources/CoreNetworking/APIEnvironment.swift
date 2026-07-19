import Foundation

/// Every environment the app can talk to. Adding a new one (e.g. `.staging`)
/// is a single new case here — nothing else in this library needs to change.
public enum APIEnvironment: String, CaseIterable, Sendable {
    case dev
    case uat
    case qa
    case prod

    public var displayName: String {
        switch self {
        case .dev: return "Development"
        case .uat: return "UAT"
        case .qa: return "QA"
        case .prod: return "Production"
        }
    }

    /// Base URL per environment. In a real project these values would
    /// come from your infra team / secrets management, not be hardcoded —
    /// but keeping them here means there is exactly ONE file to look at
    /// to answer "what does dev actually point to?"
    public var baseURL: URL {
        switch self {
        case .dev:  return URL(string: "https://api-dev.example.com")!
        case .uat:  return URL(string: "https://api-uat.example.com")!
        case .qa:   return URL(string: "https://api-qa.example.com")!
        case .prod: return URL(string: "https://api.example.com")!
        }
    }

    /// Headers sent on every request in this environment, e.g. to let
    /// your backend/API gateway tell dev traffic apart from prod traffic.
    public var defaultHeaders: [String: String] {
        ["X-App-Environment": rawValue]
    }

    /// Lower environments get a longer timeout — useful when a dev/QA
    /// backend is slower (cold starts, debug logging, no CDN) than prod.
    public var requestTimeout: TimeInterval {
        self == .prod ? 30 : 60
    }

    /// Prod should never get verbose request/response logging (payloads
    /// can contain PII). Every other environment can.
    public var allowsVerboseLogging: Bool {
        self != .prod
    }

    /// Whether testers are allowed to switch INTO this environment at
    /// runtime from an in-app debug menu. Keeping prod out of this list
    /// means a QA build can still let someone swipe over to prod data by
    /// mistake — decide deliberately per app; this default excludes it.
    public static var runtimeSwitchableEnvironments: [APIEnvironment] {
        [.dev, .uat, .qa]
    }
}
