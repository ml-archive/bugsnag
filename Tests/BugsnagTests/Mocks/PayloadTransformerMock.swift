import Vapor
import Bugsnag
import HTTP
import Stacked

internal class PayloadTransformerMock: PayloadTransformerType {
    
    let frameAddress: FrameAddressType.Type = FrameAddressMock.self
    let environment: Environment
    let apiKey: String

    var lastPayloadData: (
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        stackTrace: [String]?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        stackTraceSize: Int?,
        userId: String?,
        userName: String?,
        userEmail: String?,
        filters: [String]?
    )? = nil

    init(environment: Environment, apiKey: String) {
        self.environment = environment
        self.apiKey = apiKey
    }

    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity = .error,
        stackTrace: [String]?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        stackTraceSize: Int,
        filters: [String],
        userId: String?,
        userName: String?,
        userEmail: String?
    ) throws -> JSON {
        self.lastPayloadData = (
            message: message,
            metadata: metadata,
            request: request,
            severity: severity,
            stackTrace: stackTrace,
            lineNumber: lineNumber,
            funcName: funcName,
            fileName: fileName,
            stackTraceSize: stackTraceSize,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            filters: filters
        )

        return try JSON(node: ["transformer": "mock"])
    }
}
