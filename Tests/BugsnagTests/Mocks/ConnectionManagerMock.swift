import Vapor
import Bugsnag
import HTTP

internal class ConnectionManagerMock: ConnectionManagerType {
    var lastPayload: JSON? = nil

    internal func submitPayload(_ json: JSON) throws -> Status {
        self.lastPayload = json
        return Status.accepted // Just some random status.
    }
}
