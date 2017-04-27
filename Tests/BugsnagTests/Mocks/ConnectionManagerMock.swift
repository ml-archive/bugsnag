import Vapor
import Bugsnag
import HTTP

internal class ConnectionManagerMock: ConnectionManagerType {
    let client: ClientFactoryProtocol
    let url: String
    var lastPayload: JSON? = nil

    required init(client: ClientFactoryProtocol, url: String) {
        self.client = client
        self.url = url
    }

    internal func submitPayload(_ json: JSON) throws -> Status {
        self.lastPayload = json
        return Status.accepted // Just some random status.
    }
}
