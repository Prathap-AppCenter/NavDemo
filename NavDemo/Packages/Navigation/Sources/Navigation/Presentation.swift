/// How a route should be shown. The CALLER decides this at the navigate()
/// call site — the destination screen never knows or cares whether it was
/// pushed or presented.
public enum Presentation: Equatable {
    case push
    case sheet
    case fullScreenCover
}
