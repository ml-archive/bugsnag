import Vapor

public final class BugsnagReporter: Service, Middleware {
    public let apiKey: String
    public let releaseStage: String
    public let debug: Bool

    let hostName = "https://notify.bugsnag.com/"
    let payloadVersion: UInt8 = 4
    let app: BugsnagApp

    public init(apiKey: String, releaseStage: String, debug: Bool = false) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
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
        _ req: HTTPRequest,
        error: Error,
        severity: String,
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

        var body: String? = nil
        if let data = req.body.data {
            body = String(data: data, encoding: .utf8)
        }

        let eventRequest = BugsnagRequest(
            clientIp: req.remotePeer.hostname ?? "",
            headers: parseHeaders(headers: req.headers),
            httpMethod: "\(req.method)",
            url: req.urlString,
            referer: req.remotePeer.description,
            body: body
        )

        let metadata = BugsnagMetaData(meta: [
            "Error localized description": error.localizedDescription,
            "Request debug description": req.debugDescription
        ])

        let event = BugsnagEvent(
            payloadVersion: "4",
            exceptions: [exception],
            request: eventRequest,
            severity: severity,
            app: app,
            metaData: metadata
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
        callsite: (String, String, Int),
        on request: Request
    ) -> Future<Void> {
        do {
            let body = try buildBody(
                request.http,
                error: error,
                severity: severity,
                callsite: callsite
            )

            return HTTPClient.connect(hostname: "notify.bugsnag.com", on: request)
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
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Future<Void> {
        return report(
            severity: "info",
            error,
            callsite: (file, function, line),
            on: request
        )
    }

    @discardableResult
    public func warning(
        _ error: Error,
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Future<Void> {
        return report(
            severity: "warning",
            error,
            callsite: (file, function, line),
            on: request
        )
    }

    @discardableResult
    public func error(
        _ error: Error,
        on request: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Future<Void> {
        return report(
            severity: "error",
            error,
            callsite: (file, function, line),
            on: request
        )
    }
}
