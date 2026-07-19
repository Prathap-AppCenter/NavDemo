import XCTest
@testable import DIContainer

protocol SampleLogger { func log(_ s: String) }
struct FakeLogger: SampleLogger { func log(_ s: String) {} }

enum FakeModule: ModuleDependency {
    static var requiredDependencies: [Any.Type] { [SampleLogger.self] }
}

final class DIContainerTests: XCTestCase {
    func test_resolve_returnsRegisteredInstance() {
        let c = DIContainer()
        c.register(SampleLogger.self, instance: FakeLogger())
        XCTAssertNotNil(c.resolve(SampleLogger.self))
    }

    func test_validate_throwsWhenMissing() {
        let c = DIContainer()
        XCTAssertThrowsError(try DependencyValidator.validate(FakeModule.self, in: c))
    }

    func test_validate_passesWhenSatisfied() throws {
        let c = DIContainer()
        c.register(SampleLogger.self, instance: FakeLogger())
        XCTAssertNoThrow(try DependencyValidator.validate(FakeModule.self, in: c))
    }
}
