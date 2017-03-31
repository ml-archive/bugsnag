import Vapor
import HTTP

public final class Middleware: HTTP.Middleware {

    let drop: Droplet
    let configuration: ConfigurationType
    let reporter: ReporterType

    public init(drop: Droplet) throws {
        self.drop = drop
        self.configuration = try Configuration(drop: drop)
        self.reporter = Reporter(
            drop: drop,
            config: configuration
        )
    }

    internal init(reporter: ReporterType) throws {
        self.drop = reporter.drop
        self.configuration = reporter.config
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
