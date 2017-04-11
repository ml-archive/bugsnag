import Vapor
import Bugsnag
import HTTP

internal class PayloadTransformerMock: PayloadTransformerType {
    let drop: Droplet
    let config: ConfigurationType
    var lastPayloadData: (message: String, metadata: Node?, request: Request?, severity: Severity, filters: [String])? = nil


    required init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }

    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity = .error,
        filters: [String] = []
    ) throws -> JSON {
        self.lastPayloadData = (message: message, metadata: metadata, request: request, severity: severity, filters: filters)
        return try JSON(node: ["transformer": "mock"])
    }
}
