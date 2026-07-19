/// Auth owns this. Adding a new Auth screen means adding a case HERE —
/// in Auth's own package, reviewed by Auth's own team, with zero chance
/// of a merge conflict against Home's or Payments' route file.
public enum AuthRoute: Hashable {
    case login
    case signup
    case forgotPassword
}
