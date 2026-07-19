import Foundation

/// Each module implements its OWN parser for the URLs it owns (e.g. Auth
/// only knows how to parse "auth/..." paths). Return type is type-erased
/// because a shared protocol can't reference every module's concrete
/// Route type without reintroducing the coupling we just removed. The App
/// target — the one place allowed to know every module — is responsible
/// for unwrapping the erased value back to a concrete type before pushing
/// it (see App/Sources/CompositeDeepLinkParser.swift).
public protocol DeepLinkParser {
    func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)?
}
