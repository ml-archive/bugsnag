import Vapor
import Authentication

public final class BugsnagReporter: Service, Middleware {
    public let apiKey: String
    public let releaseStage: String
    public let debug: Bool

    let hostName = "notify.bugsnag.com"
    let payloadVersion: UInt8 = 4
    let app: BugsnagApp
    let shouldReport: Bool

    public init(
        apiKey: String,
        releaseStage: String,
        shouldReport: Bool,
        debug: Bool = false
    ) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
        self.shouldReport = shouldReport
        self.debug = debug

        app = BugsnagApp(
            releaseStage: releaseStage
        )
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        var response: Future<Response>
        
        do {
            response =  try next.respond(to: request)
        } catch let error {
            self.error(error, on: request)
            throw error
        }
        
        return response.thenIfError { error in
            return self.error(error, on: request)
                .flatMap {
                    return response
                }
        }
    }

    func parseHeaders(headers: HTTPHeaders) -> [String: String] {
        var extractedHeaders: [String:String] = [:]

        headers.forEach { header in
            extractedHeaders[header.name] = header.value
        }

        return extractedHeaders
    }

    func buildBody(
        _ req: Request,
        error: Error,
        severity: String,
        userId: Int?,
        userMetadata: [String: CustomDebugStringConvertible],
        callsite: (file: String, function: String, line: Int)
    ) throws -> LosslessHTTPBodyRepresentable {
        let notifier = BugsnagNotifier(
            name: "nodes-vapor/bugsnag",
            version: "3",
            url: "https://github.com/nodes-vapor/bugsnag.git"
        )

        let abort = error as? AbortError
        let reason = abort?.reason ?? "Something went wrong"
        let status = abort?.status ?? .internalServerError

        let exception = BugsnagException(
            errorClass: error.localizedDescription,
            message: reason,
            stacktrace: [.init(
                file: callsite.file,
                lineNumber: callsite.line,
                columnNumber: 0,
                method: callsite.function,
                inProject: true,
                code: []
            )],
            type: status.reasonPhrase
        )

        let breadcrumbs = try req.privateContainer.make(BreadcrumbContainer.self)
            .breadcrumbs

        let http = req.http

        var body: String? = nil
        if let data = http.body.data {
            body = String(data: data, encoding: .utf8)
        }

        let eventRequest = BugsnagRequest(
            clientIp: http.remotePeer.hostname ?? "",
            headers: parseHeaders(headers: http.headers),
            httpMethod: "\(http.method)",
            url: http.urlString,
            referer: http.remotePeer.description,
            body: body
        )

        var metadata: [String: String] = [
            "Error localized description": error.localizedDescription,
            "Request debug description": http.debugDescription
        ]

        metadata.reserveCapacity(2 + userMetadata.count)
        for (key, value) in userMetadata {
            metadata[key] = value.debugDescription
        }

        var user: BugsnagUser? = nil
        if let id = userId {
            user = BugsnagUser(id: "\(id)")
        }

        let event = BugsnagEvent(
            payloadVersion: "4",
            exceptions: [exception],
            breadcrumbs: breadcrumbs,
            request: eventRequest,
            unhandled: true,
            severity: severity,
            user: user,
            app: app,
            metaData: BugsnagMetaData(meta: metadata)
        )

        let payload = BugsnagPayload(
            apiKey: apiKey,
            notifier: notifier,
            events: [event]
        )

        return try JSONEncoder().encode(payload)
    }

    func report(
        severity: String,
        _ error: Error,
        userId: Int?,
        metadata: [String: CustomDebugStringConvertible],
        callsite: (String, String, Int),
        on request: Request
    ) -> Future<Void> {
        guard shouldReport else {
            return request.future()
        }

        do {
            let body = try buildBody(
                request,
                error: error,
                severity: severity,
                userId: userId,
                userMetadata: metadata,
                callsite: callsite
            )

            return HTTPClient.connect(hostname: hostName, on: request)
                .flatMap(to: HTTPResponse.self) { client in
                    let headers = HTTPHeaders([
                        ("Content-Type", "application/json"),
                        ("Bugsnag-Api-Key", self.apiKey),
                        ("Bugsnag-Payload-Version", self.payloadVersion.string)
                    ])
                    
                    let req = HTTPRequest(method: .POST, url: "/", headers: headers, body: body)
                    return client.send(req)
                }
                .map(to: Void.self) { response in
                    if self.debug {
                        print("Bugsnag response:")
                        print(response.status.code, response.status.reasonPhrase)
                    }
                }
        } catch {
            // fail silently
        }

        return request.future(Void())
    }

    @discardableResult
    public func info(
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Future<Void> {
        return report(
            severity: "info",
            error,
            userId: nil,
            metadata: metadata,
            callsite: (file, function, line),
            on: request
        )
    }

    @discardableResult
    public func warning(
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Future<Void> {
        return report(
            severity: "warning",
            error,
            userId: nil,
            metadata: metadata,
            callsite: (file, function, line),
            on: request
        )
    }

    @discardableResult
    public func error(
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Future<Void> {
        return report(
            severity: "error",
            error,
            userId: nil,
            metadata: metadata,
            callsite: (file, function, line),
            on: request
        )
    }

    // MARK: Automatic user tracking

    @discardableResult
    public func info<U: BugsnagReportableUser>(
        userType: U.Type,
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) throws -> Future<Void> {
        let userId = try request.authenticated(userType)?.id

        return report(
            severity: "info",
            error,
            userId: userId,
            metadata: metadata,
            callsite: (file, function, line),
            on: request
        )
    }

    @discardableResult
    public func warning<U: BugsnagReportableUser>(
        userType: U.Type,
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) throws -> Future<Void> {
        let userId = try request.authenticated(userType)?.id

        return report(
            severity: "warning",
            error,
            userId: userId,
            metadata: metadata,
            callsite: (file, function, line),
            on: request
        )
    }

    @discardableResult
    public func error<U: BugsnagReportableUser>(
        userType: U.Type,
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) throws -> Future<Void> {
        let userId = try request.authenticated(userType)?.id

        return report(
            severity: "error",
            error,
            userId: userId,
            metadata: metadata,
            callsite: (file, function, line),
            on: request
        )
    }
}
