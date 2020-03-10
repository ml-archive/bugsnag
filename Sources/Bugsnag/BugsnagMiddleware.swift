import Vapor

public struct BugsnagMiddleware {
    public init() { }
}

extension BugsnagMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).flatMapError { error in
            request.bugsnag.report(error)
                .flatMapThrowing { throw error }
        }
    }
}
