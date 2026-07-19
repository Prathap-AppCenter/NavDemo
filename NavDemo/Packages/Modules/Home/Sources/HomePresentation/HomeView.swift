import SwiftUI
import HomeDomain

public struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    public init(viewModel: @autoclosure @escaping () -> HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            }
            ForEach(viewModel.items) { item in
                Button(item.title) { viewModel.onItemTapped(item) }
            }
            Button("Go to Checkout") { viewModel.onCheckoutTapped() }
                .accessibilityIdentifier("home.checkout")
        }
        .navigationTitle("Home")
        .accessibilityIdentifier("home.title")
        .onAppear { viewModel.onAppear() }
    }
}

public struct ItemDetailView: View {
    let itemId: String
    public init(itemId: String) { self.itemId = itemId }
    public var body: some View {
        Text("Item detail: \(itemId)").font(.title2)
    }
}
