import Vapor
import Bugsnag
import HTTP

internal class ConnectionManagerMock: ConnectionManagerType {
    let drop: Droplet
    let config: ConfigurationType
    var lastPayload: JSON? = nil

    required init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }

    internal func submitPayload(_ json: JSON) throws -> Status {
        self.lastPayload = json
        return Status.accepted // Just some random status.
    }
}
