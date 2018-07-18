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
        let metadata = BugsnagPayload.Event.Metadata(url: request?.http.urlString ?? "")
        let app = BugsnagPayload.Event.App(releaseStage: environment.name, type: "Vapor")
        
        var headersDict = [String: String]()
        
        if let req = request {
            for header in req.http.headers {
                headersDict[header.name] = header.value
            }
        }
        
        let requestContent = BugsnagPayload.Event.Request(clientIp: request?.http.remotePeer.hostname,
                                                          headers: headersDict,
                                                          httpMethod: request?.http.method.string,
                                                          url: request?.http.url.path)
        
        let event = BugsnagPayload.Event(payloadVersion: 2,
                                         exceptions: [exception],
                                         app: app,
                                         severity: severity.rawValue,
                                         user: BugsnagPayload.Event.User(id: userId, name: userName, email: userEmail),
                                         metadata: metadata,
                                         request: requestContent)
        
        let notifier = BugsnagPayload.Notifier(name: "Bugsnag Vapor", version: "2.0.0", url: "https://github.com/gotranseo/bugsnag")
        let payload = BugsnagPayload(apiKey: apiKey, notifier: notifier, events: [event])

        return payload
    }
}
