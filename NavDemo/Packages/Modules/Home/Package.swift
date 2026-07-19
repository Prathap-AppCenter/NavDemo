// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Home",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "HomePublicAPI", targets: ["HomePublicAPI"])
    ],
    dependencies: [
        .package(path: "../../Navigation"),
        .package(path: "../../DIContainer"),
        .package(path: "../../CoreNetworking")
    ],
    targets: [
        .target(name: "HomeDomain"),
        .target(name: "HomeData", dependencies: ["HomeDomain", "CoreNetworking"]),
        .target(name: "HomePresentation", dependencies: ["HomeDomain"]),
        .target(
            name: "HomePublicAPI",
            dependencies: ["HomeDomain", "HomeData", "HomePresentation", "DIContainer", "Navigation", "CoreNetworking"]
        ),
        .executableTarget(
            name: "HomeDemoApp",
            dependencies: ["HomePublicAPI", "DIContainer", "CoreNetworking"]
        )
    ]
)
