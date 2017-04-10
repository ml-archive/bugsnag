import Vapor
import Bugsnag
import HTTP

internal class PayloadTransformerMock: PayloadTransformerType {
    let drop: Droplet
    let config: ConfigurationType
    var lastPayloadData: (message: String, metadata: Node?, request: Request?, filters: [String])? = nil

    required init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }

    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        filters: [String] = []
    ) throws -> JSON {
        self.lastPayloadData = (message: message, metadata: metadata, request: request, filters: config.filters)
        return try JSON(node: ["transformer": "mock"])
    }
}
