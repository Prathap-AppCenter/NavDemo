import Foundation
import Navigation

public struct PaymentsDeepLinkParser: DeepLinkParser {
    public init() {}

    public func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)? {
        guard url.host == "payments" else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        if path.first == "checkout",
           let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
               .queryItems?.first(where: { $0.name == "orderId" })?.value {
            return (AnyHashable(PaymentsRoute.checkout(orderId: id)), .sheet)
        }
        if path.first == "history" {
            return (AnyHashable(PaymentsRoute.history), .push)
        }
        return nil
    }
}
