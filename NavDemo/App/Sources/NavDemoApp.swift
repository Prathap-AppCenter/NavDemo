import SwiftUI

@main
struct NavDemoApp: App {
    let container = AppBootstrap.run()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
