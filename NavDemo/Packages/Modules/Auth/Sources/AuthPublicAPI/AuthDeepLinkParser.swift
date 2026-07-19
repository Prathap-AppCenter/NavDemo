import Foundation
import Navigation

/// Auth parses only URLs it owns. Nobody outside Auth needs to know these
/// rules exist, and Auth never needs to know what other modules' URL
/// schemes look like.
public struct AuthDeepLinkParser: DeepLinkParser {
    public init() {}

    public func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)? {
        guard url.host == "auth" else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        guard path.first == "login" else { return nil }
        return (AnyHashable(AuthRoute.login), .push)
    }
}
