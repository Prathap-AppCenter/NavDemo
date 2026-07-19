/// Payments owns this.
public enum PaymentsRoute: Hashable {
    case checkout(orderId: String)
    case history
    case cardDetails(cardId: String)
}
