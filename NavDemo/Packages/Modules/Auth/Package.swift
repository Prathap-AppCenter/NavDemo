// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Auth",
    platforms: [.iOS(.v16)],
    products: [
        // The ONLY target visible outside this package. AuthDomain,
        // AuthData, AuthPresentation are internal — no product entry means
        // no other package can `import` them, even if they wanted to.
        .library(name: "AuthPublicAPI", targets: ["AuthPublicAPI"])
    ],
    dependencies: [
        .package(path: "../../Navigation"),
        .package(path: "../../DIContainer"),
        .package(path: "../../CoreNetworking")
    ],
    targets: [
        // ---- Domain: pure Swift, no dependencies ----
        .target(name: "AuthDomain"),

        // ---- Data: depends on Domain + shared networking ----
        .target(name: "AuthData", dependencies: ["AuthDomain", "CoreNetworking"]),

        // ---- Presentation: depends on Domain only (never Data directly) ----
        .target(name: "AuthPresentation", dependencies: ["AuthDomain"]),

        // ---- PublicAPI: the module's single front door. Owns AuthRoute
        //      and AuthDeepLinkParser itself now — depends on Navigation
        //      only for the tiny, zero-dependency DeepLinkParser/Presentation
        //      types, never for any shared route enum. ----
        .target(
            name: "AuthPublicAPI",
            dependencies: ["AuthDomain", "AuthData", "AuthPresentation", "DIContainer", "Navigation", "CoreNetworking"]
        ),

        // ---- Demo app: lets the Auth team build & run JUST this module ----
        .executableTarget(
            name: "AuthDemoApp",
            dependencies: ["AuthPublicAPI", "DIContainer", "CoreNetworking"]
        ),

        // ---- Tests: live inside the package, so they get internal access
        //      to AuthDomain/AuthPresentation without those being products ----
        .testTarget(name: "AuthDomainTests", dependencies: ["AuthDomain"]),
        .testTarget(name: "AuthPresentationTests", dependencies: ["AuthPresentation"])
    ]
)
