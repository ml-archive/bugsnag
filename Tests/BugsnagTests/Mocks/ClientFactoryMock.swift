import Vapor
import Bugsnag
import HTTP
import Transport

internal class ClientFactoryMock: ClientFactoryProtocol {
    var lastRequest: Request?

    func respond(to request: Request) throws -> Response {
        lastRequest = request
        return Response(status: .ok)
    }

    func makeClient(
        hostname: String,
        port: Port,
        _ securityLayer: SecurityLayer
    ) throws -> ClientProtocol {
        return 0 as! ClientProtocol
    }
}

