import Vapor
import Bugsnag
import HTTP

internal class ConnectionManagerMock: ConnectionManagerType {
    let drop: Droplet
    let config: ConfigurationType
    var lastPost: (status: Status, message: String, metadata: Node?, request: Request)? = nil

    required init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }

    func post(status: Status, message: String, metadata: Node?, request: Request) throws -> Status {
        self.lastPost = (status, message, metadata, request)
        return Status.accepted // Just some random status.
    }
}
