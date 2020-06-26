import Vapor

/// Automatically catches and reports errors to Bugsnag.
///
///     app.middleware.use(BugsnagMiddleware())
///
/// This should be placed _before_ `ErrorMiddleware`. 
public struct BugsnagMiddleware {
    public init() { }
}

extension BugsnagMiddleware: Middleware {
    /// See `Middleware`.
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).flatMapErrorThrowing { error in
            request.bugsnag.report(error)
            throw error
        }
    }
}
