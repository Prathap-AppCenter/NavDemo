import Foundation
import Navigation

public struct HomeDeepLinkParser: DeepLinkParser {
    public init() {}

    public func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)? {
        guard url.host == "home" else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        if path.first == "item", path.count > 1 {
            return (AnyHashable(HomeRoute.detail(itemId: path[1])), .push)
        }
        return (AnyHashable(HomeRoute.root), .push)
    }
}
