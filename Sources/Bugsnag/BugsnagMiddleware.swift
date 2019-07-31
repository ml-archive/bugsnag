import Authentication
import Vapor

public struct BugsnagMiddleware {
    let reporter: ErrorReporter
}

extension BugsnagMiddleware: Middleware {
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        return Future
            .flatMap(on: req) {
                try next.respond(to: req)
            }
            .catchFlatMap { error in
                self.handleError(error, on: req).map { throw error }
            }
    }

    private func handleError(_ error: Error, on container: Container) -> Future<Void> {
        if let reportableError = error as? ReportableError {
            guard reportableError.shouldReport else {
                return container.future()
            }
            return self.reporter.report(
                reportableError,
                severity: reportableError.severity,
                userId: reportableError.userId,
                metadata: reportableError.metadata,
                on: container
            )
        } else {
            return self.reporter.report(error, on: container)
        }
    }
}

extension BugsnagMiddleware: ServiceType {
    public static func makeService(for container: Container) throws -> BugsnagMiddleware {
        return try .init(reporter: container.make())
    }
}
