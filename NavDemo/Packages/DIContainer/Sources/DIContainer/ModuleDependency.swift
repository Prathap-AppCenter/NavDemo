public protocol ModuleDependency {
    static var requiredDependencies: [Any.Type] { get }
}

public enum DependencyValidationError: Error, CustomStringConvertible {
    case missing(module: String, types: [String])
    public var description: String {
        switch self {
        case .missing(let module, let types):
            return "[DI] Module '\(module)' is missing dependencies: \(types.joined(separator: ", "))"
        }
    }
}

public enum DependencyValidator {
    public static func validate(_ module: ModuleDependency.Type, in container: DIContainer) throws {
        let missing = module.requiredDependencies.filter { !container.hasRegistration(for: $0) }
        guard missing.isEmpty else {
            throw DependencyValidationError.missing(
                module: String(describing: module),
                types: missing.map { String(describing: $0) }
            )
        }
    }
}
