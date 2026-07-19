// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Navigation",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Navigation", targets: ["Navigation"])
    ],
    targets: [
        // Zero dependencies — same guarantee the old NavigationContracts had.
        // Any module can import this freely without pulling in anything else.
        .target(name: "Navigation"),
        .testTarget(name: "NavigationTests", dependencies: ["Navigation"])
    ]
)
