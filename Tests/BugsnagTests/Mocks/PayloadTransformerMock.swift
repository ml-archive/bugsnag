import Vapor
import Bugsnag
import HTTP
import Stacked

internal class PayloadTransformerMock: PayloadTransformerType {
    let environment: Environment
    let apiKey: String
    let frameAddress: FrameAddressType.Type = FrameAddressMock.self

    var lastPayloadData: (message: String, metadata: Node?, request: Request?, severity: Severity, stackTraceSize: Int?, filters: [String]?)? = nil

    init(environment: Environment, apiKey: String) {
        self.environment = environment
        self.apiKey = apiKey
    }

    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity = .error,
        stackTraceSize: Int,
        filters: [String]
    ) throws -> JSON {
        self.lastPayloadData = (message: message, metadata: metadata, request: request, severity: severity, stackTraceSize: stackTraceSize, filters: filters)
        return try JSON(node: ["transformer": "mock"])
    }
}
