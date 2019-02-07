import Vapor

public final class BugsnagProvider: Provider {
    private let config: BugsnagConfig

    public init(config: BugsnagConfig) {
        self.config = config
    }

    public func register(_ services: inout Services) throws {
        services.register(BugsnagReporter(config: config), as: ErrorReporter.self)
        services.register { container in
            return BreadcrumbContainer()
        }
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}
