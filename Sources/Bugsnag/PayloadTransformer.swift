import Vapor

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
        userEmail: String?,
        version: String?,
        skipContent: Bool
        ) throws -> BugsnagPayload
}

public struct PayloadTransformer: PayloadTransformerType {
    
    public let environment: Environment
    public let apiKey: String
    
    public init(environment: Environment, apiKey: String) {
        self.environment = environment
        self.apiKey = apiKey
    }
    
    public func payloadFor(
        message: String,
        request: Request?,
        severity: Severity,
        lineNumber: Int? = nil,
        funcName: String? = nil,
        fileName: String? = nil,
        userId: String?,
        userName: String?,
        userEmail: String?,
        version: String?,
        skipContent: Bool
    ) throws -> BugsnagPayload {
        
        let stacktrace = BugsnagPayload.Event.Stacktrace(file: fileName ?? "",
                                                         lineNumber: lineNumber ?? 0,
                                                         columnNumber: 0,
                                                         method: funcName ?? "")

        let metadata = BugsnagPayload.Event.Metadata(url: request?.url.string ?? "")
        if let requestBodyData = request?.body.data, let requestString = String(data: Data(requestBodyData.readableBytesView), encoding: .utf8), !skipContent {
            metadata.requestBody = .init(body: requestString.replacingOccurrences(of: "\"", with: "'"))
        }

        let exception = BugsnagPayload.Event.Exception(errorClass: message, message: message, stacktrace: [stacktrace])
        let app = BugsnagPayload.Event.App(releaseStage: environment.name, type: "Vapor", version: version)
        
        var headersDict = [String: String]()
        
        if let req = request {
            for header in req.headers {
                // Don't send the authorization header
                guard header.name.lowercased() != "authorization" else { continue }
                headersDict[header.name] = header.value
            }
        }
        
        let requestContent = BugsnagPayload.Event.Request(clientIp: request?.remoteAddress?.hostname,
                                                          headers: headersDict,
                                                          httpMethod: request?.method.string,
                                                          url: request?.url.path)
        
        let event = BugsnagPayload.Event(payloadVersion: 2,
                                         exceptions: [exception],
                                         app: app,
                                         severity: severity.rawValue,
                                         user: BugsnagPayload.Event.User(id: userId, name: userName, email: userEmail),
                                         metaData: metadata,
                                         request: requestContent)
        
        let notifier = BugsnagPayload.Notifier(name: "Bugsnag Vapor", version: "2.0.0", url: "https://github.com/gotranseo/bugsnag")
        let payload = BugsnagPayload(apiKey: apiKey, notifier: notifier, events: [event])

        return payload
    }
}
