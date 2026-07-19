import PaymentsPresentation

final class DemoPaymentsRouter: PaymentsRouting {
    func navigateToHistory() { print("[PaymentsDemo] would navigate to history") }
    func dismiss() { print("[PaymentsDemo] dismiss") }
}
