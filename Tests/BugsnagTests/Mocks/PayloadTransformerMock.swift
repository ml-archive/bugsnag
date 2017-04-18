import Vapor
import Bugsnag
import HTTP

internal class PayloadTransformerMock: PayloadTransformerType {
    let environment: Environment
    let apiKey: String

    var lastPayloadData: (message: String, metadata: Node?, request: Request?, severity: Severity, stackTraceSize: Int, filters: [String])? = nil

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
        filters: [String] = []
    ) throws -> JSON {
        self.lastPayloadData = (message: message, metadata: metadata, request: request, severity: severity, stackTraceSize: stackTraceSize, filters: filters)
        return try JSON(node: ["transformer": "mock"])
    }
}
