import Vapor
import HTTP

public final class Middleware: HTTP.Middleware, ConfigInitializable {
    let reporter: ReporterType

    public init(config: Config) throws {
        self.reporter = try ReporterFactory.make(config: config)
    }

    internal init(reporter: ReporterType) throws {
        self.reporter = reporter
    }


    // MARK: - Middleware

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch let error {
            try self.reporter.report(error: error, request: request)
            throw error
        }
    }
}
