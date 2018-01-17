import Vapor
import HTTP

public protocol PayloadTransformerType {
    var environment: Environment { get }
    var apiKey: String { get }

    func payloadFor(
        message: String,
        request: Request?,
        severity: Severity,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        userId: String?,
        userName: String?,
        userEmail: String?
        ) throws -> BugsnagPayload
}

internal struct PayloadTransformer: PayloadTransformerType {
    
    let environment: Environment
    let apiKey: String
    
    internal func payloadFor(
        message: String,
        request: Request?,
        severity: Severity,
        lineNumber: Int? = nil,
        funcName: String? = nil,
        fileName: String? = nil,
        userId: String?,
        userName: String?,
        userEmail: String?
        ) throws -> BugsnagPayload {
        
        let stacktrace = BugsnagPayload.Event.Stacktrace(file: fileName ?? "",
                                                         lineNumber: lineNumber ?? 0,
                                                         columnNumber: 0,
                                                         method: funcName ?? "")
        
        let exception = BugsnagPayload.Event.Exception(errorClass: message, message: message, stacktrace: [stacktrace])
        let metadata = BugsnagPayload.Event.Metadata(method: request?.method.string ?? "", url: request?.uri.description ?? "")
        let app = BugsnagPayload.Event.App(releaseStage: environment.name, type: "Vapor")
        
        let event = BugsnagPayload.Event(payloadVersion: 2,
                                         exceptions: [exception],
                                         app: app,
                                         severity: severity.rawValue,
                                         user: BugsnagPayload.Event.User(id: userId, name: userName, email: userEmail),
                                         metadata: metadata)
        
        let notifier = BugsnagPayload.Notifier(name: "Bugsnag Vapor", version: "2.0.0", url: "https://github.com/mcdappdev/bugsnag")
        let payload = BugsnagPayload(apiKey: apiKey, notifier: notifier, events: [event])

        return payload
    }
}
