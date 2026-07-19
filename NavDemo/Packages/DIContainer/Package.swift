// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DIContainer",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "DIContainer", targets: ["DIContainer"])
    ],
    targets: [
        .target(name: "DIContainer"),
        .testTarget(name: "DIContainerTests", dependencies: ["DIContainer"])
    ]
)
