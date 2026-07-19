# NavDemo

A working, buildable sample of a modular SwiftUI app: independent `Auth`,
`Home`, and `Payments` modules that each own their own screens and
navigation, wired together by a thin App target, with dependency
injection, push/present navigation, and deep linking all working
end-to-end.

This README explains the whole project — what each piece is for, how the
pieces fit together, and how to actually run it.

---

## 1. The problem this project solves

A single iOS app with 100+ screens, built by multiple teams, runs into
four recurring problems:

1. **Screens step on each other.** If every screen can `import` any other
   screen directly, the whole app becomes one tangled dependency graph —
   changing one feature risks breaking screens that "happened" to import
   it.
2. **Navigation code sprawls.** Deciding whether to push or present a
   screen, and wiring up deep links / push notifications, tends to get
   duplicated ad hoc across the app instead of going through one system.
3. **Shared services (networking, analytics, storage) get wired
   inconsistently** — some screens build their own `URLSession`, others
   reach for a singleton, and nobody can tell what a screen actually
   depends on without reading its entire implementation.
4. **Teams can't work independently.** Building "just the Checkout
   screen" often means compiling the entire app.

This project's structure is a direct answer to each of those four points.

---

## 2. Project structure

```
NavDemo/
├── project.yml                    ← XcodeGen spec for the FULL app
├── App/                            ← the ONLY target that imports every module together
│   ├── Sources/
│   │   ├── NavDemoApp.swift        (@main entry point)
│   │   ├── AppBootstrap.swift      (registers shared services, validates modules)
│   │   ├── AppRouter.swift         (the one real NavigationPath in the app)
│   │   ├── RootView.swift          (turns routes into real screens)
│   │   └── Routing/
│   │       ├── AuthRoutingAdapter.swift
│   │       ├── HomeRoutingAdapter.swift
│   │       └── PaymentsRoutingAdapter.swift
│   └── Tests/
│       └── DeepLinkDispatchTests.swift
│
└── Packages/
    ├── Navigation/                 ← Router + DeepLinkParser protocols, zero deps
    ├── DIContainer/                ← the dependency injection container
    ├── CoreNetworking/             ← NetworkClient protocol + mock implementation
    └── Modules/
        ├── Auth/                   ← ONE package, several internal targets
        │   ├── Package.swift
        │   └── Sources/
        │       ├── AuthDomain/         (business logic — pure Swift)
        │       ├── AuthData/           (repositories — talks to the network)
        │       ├── AuthPresentation/   (Views + ViewModels + AuthRouting protocol)
        │       ├── AuthPublicAPI/      (the ONLY importable target — AuthModule, AuthRoute, AuthDeepLinkParser)
        │       └── AuthDemoApp/        (a runnable app for JUST this module)
        ├── Home/                   (identical shape to Auth)
        └── Payments/               (identical shape, minus a Data layer — simpler module)
```

Six packages total, plus the App target. Every one of the three modules
follows the exact same internal shape, so once you understand `Auth`, you
understand `Home` and `Payments` too.

---

## 3. Why Swift Package Manager, and why "one package per module"

**Why SPM at all:** SPM packages give you something a folder of files
can't — a compiler-enforced boundary. What a package exposes to the
outside world is controlled by its `products:` list in `Package.swift`.
If a target isn't listed there, no other package can `import` it, full
stop. That's the mechanism this whole architecture leans on.

**Why one package per module, not one package per layer:** an earlier
version of this project gave each layer (`AuthDomain`, `AuthData`,
`AuthPresentation`, `AuthPublicAPI`) its own separate package. That's the
*strictest* possible isolation, but it's four `Package.swift` files, four
folders, four sets of paths to keep in sync — for isolation you can get
just as well with **one package, four targets**:

```swift
// Packages/Modules/Auth/Package.swift
let package = Package(
    name: "Auth",
    products: [
        // Only ONE target is exposed. AuthDomain, AuthData, AuthPresentation
        // are internal — no product entry means no other package can
        // import them, even if someone tried to.
        .library(name: "AuthPublicAPI", targets: ["AuthPublicAPI"])
    ],
    targets: [
        .target(name: "AuthDomain"),
        .target(name: "AuthData", dependencies: ["AuthDomain", "CoreNetworking"]),
        .target(name: "AuthPresentation", dependencies: ["AuthDomain"]),
        .target(name: "AuthPublicAPI", dependencies: ["AuthDomain", "AuthData", "AuthPresentation", ...]),
        .executableTarget(name: "AuthDemoApp", dependencies: ["AuthPublicAPI", ...]),
        .testTarget(name: "AuthDomainTests", dependencies: ["AuthDomain"]),
        .testTarget(name: "AuthPresentationTests", dependencies: ["AuthPresentation"])
    ]
)
```

Same compiler-enforced guarantee — `products:` still lists only
`AuthPublicAPI` — for a fraction of the file overhead, and it maps to how
teams actually think about ownership: "the Auth team owns the `Auth`
folder," full stop, not "the Auth team owns four scattered folders."

**Advantages this gives you concretely:**
- A team can `git blame`/`CODEOWNERS`-gate one folder and own it end to end.
- `swift build` / `swift test` inside `Packages/Modules/Auth` builds and
  tests *only* Auth — CI can parallelize this across modules.
- A change inside `AuthData` can never accidentally leak into another
  module's build, because nothing outside `Auth` can even see it exists.

---

## 4. Inside a module: the four layers

Every module follows Clean Architecture-style layering:

| Layer | Contains | Depends on |
|---|---|---|
| **Domain** | Entities (`User`, `Item`), repository *protocols*, use case logic | Nothing (pure Swift) |
| **Data** | Repository *implementations*, DTOs, network calls | Domain, `CoreNetworking` |
| **Presentation** | SwiftUI Views, `@MainActor` ViewModels, the module's own `*Routing` protocol | Domain only (never Data directly) |
| **PublicAPI** | The module's single front door: a factory (`AuthModule.makeView`), the module's `Route` enum, its `DeepLinkParser` | All three layers above, plus `DIContainer` and `Navigation` |

**Why split Domain from Presentation at all?** Business logic (validating
an email, deciding login succeeded) has nothing to do with SwiftUI. Look
at `AuthDomain/LoginUseCase.swift` — it's plain Swift, no `import SwiftUI`
anywhere, so it's trivially unit-testable with no UI involved:

```swift
public struct LoginUseCaseImpl: LoginUseCase {
    public func execute(email: String, password: String) async throws -> User {
        guard email.contains("@"), email.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.invalidCredentials }
        return try await repository.login(email: email, password: password)
    }
}
```

`AuthPresentation/LoginViewModel.swift` then just orchestrates this use
case and updates `@Published` state — it doesn't duplicate the validation
logic, and it never talks to the network directly.

---

## 5. DIContainer — dependency injection

### What it is

A minimal, thread-safe key-value store keyed by type, plus a validator.

```swift
// Packages/DIContainer/Sources/DIContainer/DIContainer.swift
public final class DIContainer: @unchecked Sendable {
    public static let shared = DIContainer()
    private var services: [ObjectIdentifier: Any] = [:]
    private let lock = NSRecursiveLock()

    public func register<T>(_ type: T.Type, instance: T) { ... }
    public func resolve<T>(_ type: T.Type = T.self) -> T? { ... }
    public func hasRegistration(for type: Any.Type) -> Bool { ... }
}
```

### How modules declare what they need

Each module's `PublicAPI` conforms to `ModuleDependency`:

```swift
// HomeModule.swift
public enum HomeModule: ModuleDependency {
    public static var requiredDependencies: [Any.Type] { [NetworkClient.self] }

    public static func makeView(for route: HomeRoute, container: DIContainer, router: HomeRouting) -> some View {
        let network = container.resolve(NetworkClient.self)!   // safe: validated at bootstrap
        ...
    }
}
```

### How it gets validated

```swift
// App/Sources/AppBootstrap.swift
enum AppBootstrap {
    static func run() -> DIContainer {
        let container = DIContainer.shared
        container.register(NetworkClient.self, instance: MockNetworkClient())

        let modules: [ModuleDependency.Type] = [AuthModule.self, HomeModule.self, PaymentsModule.self]
        for module in modules {
            try? DependencyValidator.validate(module, in: container)  // fails loudly in Debug if unmet
        }
        return container
    }
}
```

### How to use it — the pattern to copy for a new module

1. Add `enum YourModule: ModuleDependency` in your module's `PublicAPI`,
   listing every protocol type it needs resolved.
2. Register a real implementation of each type in `AppBootstrap.run()`.
3. Resolve it inside `makeView(for:container:router:)` when building a
   screen that needs it.
4. For that module's own standalone demo app (see §8), register a
   mock/fake for the same types and call `DependencyValidator.validate`
   there too — see `HomeDemoApp.swift` for a worked example that shows a
   caught-missing-dependency error in the UI instead of crashing.

### Advantages

- **One source of truth for shared services** — `NetworkClient` is built
  once in `AppBootstrap`, not re-instantiated per screen.
- **Fails at launch, not three taps deep.** Forgetting to register
  something a module needs throws immediately at bootstrap, with a
  message naming exactly which type is missing.
- **Modules stay protocol-based**, which is what makes them independently
  testable — a module's code never constructs its own dependencies, it's
  always handed protocol-typed instances from outside.

---

## 6. Navigation — the Feature-Scoped Router Pattern

### The two levels

| | Owns | Knows about |
|---|---|---|
| **Module-level Router** (e.g. `AuthRouting`) | Nothing visual — just a protocol, defined by the module itself | Only that module's own navigation events |
| **App-level Router** (`Router` / `AppRouter`) | The real `NavigationPath`, real `.sheet`/`.fullScreenCover` state | Nothing about specific modules — it's fully generic |

### Why a module needs its own Router protocol

`Auth` must never import `Home`, even though "login succeeded" needs to
navigate to Home. The fix: Auth declares what *it* needs, in its own
words, and never mentions Home by name.

```swift
// AuthPresentation/AuthRouting.swift — Auth owns this
public protocol AuthRouting: AnyObject {
    func navigateToHome()
    func navigateToSignup()
    func navigateToForgotPassword()
    func dismiss()
}
```

`LoginViewModel` only ever talks to `AuthRouting` — never to a concrete
router class:

```swift
private weak var router: AuthRouting?   // protocol, not a concrete type — and weak, to avoid a retain cycle
...
router?.navigateToHome()                 // Auth just "asks"
```

### The Route type — owned by each module, not shared

There is **no single shared `AppRoute` enum**. Each module defines its
own:

```swift
// AuthPublicAPI/AuthRoute.swift
public enum AuthRoute: Hashable { case login, signup, forgotPassword }

// HomePublicAPI/HomeRoute.swift
public enum HomeRoute: Hashable { case root, detail(itemId: String) }

// PaymentsPublicAPI/PaymentsRoute.swift
public enum PaymentsRoute: Hashable { case checkout(orderId: String), history, cardDetails(cardId: String) }
```

**Why:** a single shared enum, with every module adding cases to the same
file, becomes an ownerless shared resource every team has to touch —
real merge-conflict and code-review-bottleneck surface once a module has
"lots of screens." Each module's `Route` living in its own package means
shipping a new screen only ever touches that module's own file.

### The generic Router protocol

```swift
// Navigation/Router.swift
public enum Presentation { case push, sheet, fullScreenCover }

@MainActor
public protocol Router: AnyObject {
    func navigate<Route: Hashable>(to route: Route, presentation: Presentation)
    func pop()
    func popToRoot()
    func dismiss()
}
```

Generic over `Route`, so it works for any module's route type without
needing to know it in advance.

### AppRouter — the only place a real NavigationPath exists

```swift
// App/Sources/AppRouter.swift
@MainActor
final class AppRouter: ObservableObject, Router {
    @Published var path = NavigationPath()
    @Published var presentedSheet: IdentifiableRoute?
    @Published var presentedFullScreen: IdentifiableRoute?

    func navigate<Route: Hashable>(to route: Route, presentation: Presentation) {
        switch presentation {
        case .push:
            // Wrapped in AnyHashable deliberately — see below.
            path.append(AnyHashable(route))
        case .sheet:
            presentedSheet = IdentifiableRoute(value: AnyHashable(route))
        case .fullScreenCover:
            presentedFullScreen = IdentifiableRoute(value: AnyHashable(route))
        }
    }
    // pop / popToRoot / dismiss ...
}
```

### The Adapter — bridging a module's protocol to the real router

This is the piece that makes cross-module navigation possible without a
circular import. It lives in the **App target**, never inside a module:

```swift
// App/Sources/Routing/AuthRoutingAdapter.swift
@MainActor
final class AuthRoutingAdapter: AuthRouting {
    private let appRouter: Router
    init(appRouter: Router) { self.appRouter = appRouter }

    func navigateToHome() {
        appRouter.popToRoot()
        appRouter.navigate(to: HomeRoute.root, presentation: .push)   // "Home" is named here, and only here
    }
    func navigateToSignup() { appRouter.navigate(to: AuthRoute.signup, presentation: .push) }
    func navigateToForgotPassword() { appRouter.navigate(to: AuthRoute.forgotPassword, presentation: .push) }
    func dismiss() { appRouter.dismiss() }
}
```

`LoginViewModel` calls `router.navigateToHome()` believing it's talking to
some `AuthRouting`; at runtime that's actually an `AuthRoutingAdapter`.
Auth's compiled code never references `HomeRoute` — only this App-target
adapter does. Every module gets its own adapter (`HomeRoutingAdapter`,
`PaymentsRoutingAdapter`), all following this exact shape.

### RootView — a single `.navigationDestination`

```swift
// App/Sources/RootView.swift
NavigationStack(path: $router.path) {
    AuthModule.makeView(for: .login, container: container, router: AuthRoutingAdapter(appRouter: router))
        .navigationDestination(for: AnyHashable.self) { erasedRoute in
            buildAny(erasedRoute)
        }
}
.sheet(item: $router.presentedSheet) { wrapped in buildAny(wrapped.value) }
.fullScreenCover(item: $router.presentedFullScreen) { wrapped in buildAny(wrapped.value) }
```

```swift
@ViewBuilder
private func buildAny(_ route: AnyHashable) -> some View {
    if let r = route.base as? AuthRoute {
        AuthModule.makeView(for: r, container: container, router: AuthRoutingAdapter(appRouter: router))
    } else if let r = route.base as? HomeRoute {
        HomeModule.makeView(for: r, container: container, router: HomeRoutingAdapter(appRouter: router))
    } else if let r = route.base as? PaymentsRoute {
        PaymentsModule.makeView(for: r, container: container, router: PaymentsRoutingAdapter(appRouter: router))
    } else {
        EmptyView()
    }
}
```

**Why `AnyHashable`:** `NavigationPath` looks up `.navigationDestination`
handlers by the *concrete type* of what's stored. Wrapping every pushed
value in `AnyHashable` before appending means every push shares one type,
so one registration handles every module — instead of needing a new
`.navigationDestination(for: SomeModuleRoute.self)` line every time a
module is added. `buildAny` — the same cascade already needed for
sheets — now handles push, sheet, fullScreenCover, and deep links
uniformly.

**The honest trade-off:** this cascade is an `as?` chain, not a
compiler-exhaustive `switch`. Forgetting to add a case for a new module
here fails **silently** (renders `EmptyView`) rather than failing to
build. `App/Tests/DeepLinkDispatchTests.swift` exists specifically to
catch this class of mistake with real test coverage. If your team prefers
push to stay compiler-checked, `AppRouter.navigate`'s `.push` case can
revert to `path.append(route)` (no `AnyHashable` wrap) and `RootView` back
to three separate `.navigationDestination(for: <Module>Route.self)`
calls — a small, self-contained change either direction.

### Cross-module navigation example, end to end

`Home → Payments` (tapping "Go to Checkout" on the Home screen):

```
HomeViewModel.onCheckoutTapped()
    → router?.navigateToPaymentsCheckout(orderId:)      HomeRouting protocol (Home owns it)
    → HomeRoutingAdapter.navigateToPaymentsCheckout(...)  lives in App target
    → appRouter.navigate(to: PaymentsRoute.checkout(...), presentation: .sheet)
    → AppRouter.presentedSheet = IdentifiableRoute(...)
    → RootView's .sheet fires → buildAny(...) → PaymentsModule.makeView(for: .checkout(...))
    → CheckoutView appears as a sheet
```

### Advantages of this whole system

- **No module ever imports another module** — verified by the compiler,
  not by convention.
- **The caller decides push vs. present**, never the destination screen —
  the same screen can be pushed in one context and sheet-presented in
  another.
- **Adding a screen only touches that module's own files.**
- **Adding a module** touches exactly `RootView`'s `buildAny` (one `if let`
  branch) and one new `RoutingAdapter` file — nowhere else.

---

## 7. Deep linking

### Each module parses only its own URLs

```swift
// Navigation/DeepLinkParser.swift
public protocol DeepLinkParser {
    func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)?
}
```

```swift
// AuthPublicAPI/AuthDeepLinkParser.swift
public struct AuthDeepLinkParser: DeepLinkParser {
    public func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)? {
        guard url.host == "auth" else { return nil }             // not mine
        let path = url.pathComponents.filter { $0 != "/" }
        guard path.first == "login" else { return nil }
        return (AnyHashable(AuthRoute.login), .push)
    }
}
```

```swift
// PaymentsPublicAPI/PaymentsDeepLinkParser.swift — also decides Presentation
public func parse(url: URL) -> (route: AnyHashable, presentation: Presentation)? {
    guard url.host == "payments" else { return nil }
    ...
    if path.first == "checkout", let id = ... {
        return (AnyHashable(PaymentsRoute.checkout(orderId: id)), .sheet)   // sheet, like the in-app tap
    }
    ...
}
```

### The App target tries each parser in turn

```swift
// RootView.swift
private let deepLinkParsers: [DeepLinkParser] = [
    AuthDeepLinkParser(), HomeDeepLinkParser(), PaymentsDeepLinkParser()
]

.onOpenURL { url in
    for parser in deepLinkParsers {
        if let (route, presentation) = parser.parse(url: url) {
            router.navigate(to: route, presentation: presentation)
            break
        }
    }
}
```

From here it rejoins the exact same path an in-app tap takes — same
`router.navigate`, same `AppRouter`, same `buildAny`. Push notifications
work the same way: your `UNUserNotificationCenterDelegate` extracts a URL
string from the payload and calls the same parsing + `navigate` path.

### How to use it — testing a deep link

```bash
xcrun simctl openurl booted "myapp://payments/checkout?orderId=xyz"
```
(Requires `myapp` registered as a URL scheme in the App target's Info
tab.) Should present the Checkout sheet, cold-launching the app straight
to it if needed.

### Advantages

- **One URL → one code path.** Universal links, custom scheme links, and
  push notifications all funnel through the same `router.navigate` call
  in-app taps use — no duplicated navigation logic anywhere.
- **A module's URL grammar is that module's own business.** Nobody
  outside `Payments` needs to know or care what `payments/checkout` looks
  like.
- **Testable without a simulator** — `AuthDeepLinkParser().parse(url:)` is
  a pure function; see `App/Tests/DeepLinkDispatchTests.swift`.

---

## 8. Demo apps — running one module in isolation

Every module ships an `executableTarget` that boots *only itself*:

```swift
// Auth/Package.swift
.executableTarget(name: "AuthDemoApp", dependencies: ["AuthPublicAPI", "DIContainer", "CoreNetworking"])
```

```swift
// AuthDemoApp.swift
@main
struct AuthDemoApp: App {
    init() {
        DIContainer.shared.register(NetworkClient.self, instance: MockNetworkClient())
    }
    var body: some Scene {
        WindowGroup {
            AuthModule.makeView(for: .login, container: .shared, router: DemoAuthRouter())
        }
    }
}
```

`DemoAuthRouter` implements `AuthRouting` with `print()` statements
instead of real navigation — Auth never needs Home or Payments to exist to
be developed and clicked through.

`HomeDemoApp` goes one step further and shows what to do when a module has
a *real* dependency (`NetworkClient`): it registers a mock and calls
`DependencyValidator.validate` itself, surfacing a friendly in-UI error
instead of crashing if a dependency was forgotten — see
`HomeDemoApp.swift`.

### How to use it

```bash
open Packages/Modules/Auth/Package.swift
```
Pick the `AuthDemoApp` scheme in Xcode, run. No `.xcodeproj` file needed.

For a persistent, standalone `.xcodeproj` instead (useful for CI archive
steps or Instruments profiling of just one module):
```bash
cd Packages/Modules/Home
xcodegen generate
open HomeModule.xcodeproj
```
`Packages/Modules/Home/project.yml` is a *second*, module-scoped XcodeGen
spec — separate from the root one — that only references Home's actual
dependencies.

### Advantages

- Build and run one module in seconds, without the other 2+ (or, at real
  scale, 20+) modules needing to compile.
- Instant SwiftUI Previews / simulator iteration for whoever owns that
  module.
- Demo a feature to stakeholders without the whole app needing to be in a
  working state.
- CI can build + test each module's package independently and in
  parallel.

---

## 9. Running the full app

```bash
brew install xcodegen   # one-time
cd NavDemo
xcodegen generate
open NavDemo.xcodeproj
```
Select the `NavDemo` scheme, run. Log in (any email with `@`/`.`,
password 6+ characters — there's no real backend, `MockNetworkClient`
stands in), tap through Home, tap "Go to Checkout" to see cross-module,
sheet-presented navigation in action.

---

## 10. Running the tests

```bash
cd Packages/DIContainer && swift test
cd ../Navigation && swift test
cd ../Modules/Auth && swift test        # AuthDomainTests + AuthPresentationTests
```
`App/Tests/DeepLinkDispatchTests.swift` runs as part of the `NavDemoTests`
target once you've generated `NavDemo.xcodeproj` (Domain/DIContainer/
Navigation tests are pure Swift and can run on Linux CI too; Presentation
and App-level tests need Xcode's toolchain since they touch SwiftUI).

---

## 11. Adding a new module — the full checklist

1. `Packages/Modules/<Name>/Package.swift` — one package, targets:
   `<Name>Domain`, `<Name>Data`, `<Name>Presentation`, `<Name>PublicAPI`,
   `<Name>DemoApp`. Only `<Name>PublicAPI` listed under `products:`.
2. `Domain`: entities + repository/use case protocols. Pure Swift.
3. `Data`: repository implementations, depends on `Domain` + `CoreNetworking`.
4. `Presentation`: define `<Name>Routing` (only the nav events *this*
   module raises), Views + `@MainActor` ViewModels.
5. `PublicAPI`: `<Name>Route` enum, `<Name>DeepLinkParser`, and
   `<Name>Module: ModuleDependency` with `makeView(for:container:router:)`.
6. `DemoApp`: a runnable `@main App` that registers mocks for whatever
   `requiredDependencies` lists, calls `DependencyValidator.validate`, and
   builds the module's root screen with a print-based fake router.
7. In the App target: add a `<Name>RoutingAdapter: <Name>Routing`.
8. Add the module to `AppBootstrap.run()`'s `modules` array.
9. Add one `if let r = route.base as? <Name>Route { ... }` branch to
   `RootView.buildAny(_:)`.
10. Add `<Name>DeepLinkParser()` to `RootView.deepLinkParsers`.
11. Write Domain + Presentation unit tests; add a deep link parsing test
    alongside the existing ones in `DeepLinkDispatchTests.swift`.

Steps 7–10 are the *only* shared files a new module ever touches — and
they're touched once, when the module is created, never again for that
module's individual screens.

---

## 12. The circular dependency question, answered

**Can a module import the App target back, if the App target imports
every module?** No — SPM's dependency graph must be acyclic. `App → Auth`
plus `Auth → App` is a cycle and simply fails to resolve.

This project avoids it because the dependency arrow only ever points one
way: `App → Module`, never the reverse. `Auth/Package.swift` depends on
`Navigation`, `DIContainer`, `CoreNetworking` — never on `App`. Auth
defines `AuthRouting` itself, at no cost (a protocol declaration needs no
import), and the App target supplies the concrete `AuthRoutingAdapter`
that fulfills it — handed to Auth as a plain constructor parameter, not
resolved via any import inside Auth. This is Dependency Inversion, and
it's the mechanism that makes "modules never import each other, but still
navigate to each other" possible at all.

---

## Summary — what you get from all of this

- **Compiler-enforced module boundaries**, not convention-based ones.
- **One team, one folder, one build.** Any module can be built, tested,
  previewed, and demoed on its own.
- **Navigation that scales with modules, not screens.** Adding a screen
  never touches shared files; adding a module touches a small, fixed set
  of them.
- **Deep links, push notifications, and in-app taps** all resolve through
  one system, not three.
- **Dependencies are explicit and validated at launch**, not discovered
  as crashes deep inside a ViewModel.
- **Every architectural trade-off in this project is written down** in
  the code's own doc comments — nothing here is "magic," and every
  shortcut (like the `AnyHashable` cascade) is paired with the reasoning
  for taking it and a test that mitigates its risk.
