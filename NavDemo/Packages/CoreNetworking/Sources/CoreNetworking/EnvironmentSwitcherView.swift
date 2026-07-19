import SwiftUI

/// Drop this into a debug menu / shake gesture / settings screen in
/// non-prod builds so QA and internal testers can flip environments
/// without a rebuild. Because DefaultNetworkClient re-reads
/// `environmentProvider.current` on every request, the switch takes
/// effect on the very next network call.
public struct EnvironmentSwitcherView: View {
    @ObservedObject private var box: EnvironmentBox

    public init(provider: EnvironmentProvider) {
        self.box = EnvironmentBox(provider: provider)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Environment").font(.headline)
            Picker("Environment", selection: $box.current) {
                ForEach(APIEnvironment.runtimeSwitchableEnvironments, id: \.self) { env in
                    Text(env.displayName).tag(env)
                }
            }
            .pickerStyle(.segmented)
            Text("Currently pointed at: \(box.current.baseURL.absoluteString)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// EnvironmentProvider isn't an ObservableObject itself (it needs to stay
/// a plain, injectable protocol for the network layer) — this small
/// bridge is what lets SwiftUI observe and drive changes to it.
@MainActor
private final class EnvironmentBox: ObservableObject {
    private let provider: EnvironmentProvider
    @Published var current: APIEnvironment {
        didSet { provider.current = current }
    }
    init(provider: EnvironmentProvider) {
        self.provider = provider
        self.current = provider.current
    }
}
