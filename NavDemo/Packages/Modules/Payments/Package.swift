// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Payments",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "PaymentsPublicAPI", targets: ["PaymentsPublicAPI"])
    ],
    dependencies: [
        .package(path: "../../Navigation"),
        .package(path: "../../DIContainer")
    ],
    targets: [
        .target(name: "PaymentsPresentation"),
        .target(
            name: "PaymentsPublicAPI",
            dependencies: ["PaymentsPresentation", "DIContainer", "Navigation"]
        ),
        .executableTarget(
            name: "PaymentsDemoApp",
            dependencies: ["PaymentsPublicAPI", "DIContainer"]
        )
    ]
)
