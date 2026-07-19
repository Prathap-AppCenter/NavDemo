public struct Item: Equatable, Sendable, Identifiable, Decodable {
    public let id: String
    public let title: String
    public init(id: String, title: String) { self.id = id; self.title = title }
}

public protocol ItemRepository: Sendable {
    func fetchItems() async throws -> [Item]
}
