/// Home owns this. New Home screens only ever touch this file, inside
/// Home's own package.
public enum HomeRoute: Hashable {
    case root
    case detail(itemId: String)
}
