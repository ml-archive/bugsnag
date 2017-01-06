import Vapor
import Bugsnag
import HTTP

internal class ErrorResponderMock: Responder {
    let errorToThrow: Error
    init(error: Error) {
        errorToThrow = error
    }

    func respond(to request: Request) throws -> Response {
        throw self.errorToThrow
    }
}
