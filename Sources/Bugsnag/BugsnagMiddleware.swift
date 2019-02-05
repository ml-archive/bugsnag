import Authentication
import Vapor

public struct BugsnagMiddleware {
    let reporter: BugsnagReporter
}

extension BugsnagMiddleware: Middleware {
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        return Future.flatMap(on: req) {
                try next.respond(to: req)
            }.catchFlatMap { error in
                self.reporter.error(error, on: req)
                throw error
            }
    }
}

extension BugsnagMiddleware: ServiceType {
    public static func makeService(for container: Container) throws -> BugsnagMiddleware {
        return try .init(reporter: container.make())
    }
}
