import Vapor

public struct BugsnagReporter: Service {
    private let app: BugsnagApp
    private let config: BugsnagConfig
    private let headers: HTTPHeaders

    private let hostName = "notify.bugsnag.com"
    private let jsonEncoder = JSONEncoder()
    private let notifier = BugsnagNotifier(
        name: "nodes-vapor/bugsnag",
        url: "https://github.com/nodes-vapor/bugsnag.git",
        version: "3"
    )
    private let payloadVersion = "4"
    private let sendReport: (String, HTTPHeaders, Data, Request) -> Future<HTTPResponse>

    public init(
        config: BugsnagConfig,
        sendReport: ((String, HTTPHeaders, Data, Request) -> Future<HTTPResponse>)? = nil
    ) {
        self.config = config

        self.sendReport = sendReport ?? { (hostName, headers, body, req) in
            HTTPClient
                .connect(hostname: hostName, on: req)
                .flatMap(to: HTTPResponse.self) { client in
                    client.send(.init(method: .POST, headers: headers, body: body))
                }
        }

        app = BugsnagApp(
            releaseStage: config.releaseStage
        )
        headers = .init([
            ("Content-Type", "application/json"),
            ("Bugsnag-Api-Key", config.apiKey),
            ("Bugsnag-Payload-Version", payloadVersion)
        ])
    }
}

extension BugsnagReporter: ErrorReporter {
    private func buildBody(
        _ req: Request,
        error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String: CustomDebugStringConvertible],
        stacktrace: BugsnagStacktrace
    ) throws -> Data {
        let breadcrumbs: [BugsnagBreadcrumb] = (try? req.privateContainer
            .make(BreadcrumbContainer.self))?
            .breadcrumbs ?? []

        let event = BugsnagEvent(
            app: app,
            breadcrumbs: breadcrumbs,
            error: error,
            httpRequest: req.http,
            metadata: metadata,
            payloadVersion: payloadVersion,
            severity: severity,
            stacktrace: stacktrace,
            userId: userId
        )

        let payload = BugsnagPayload(
            apiKey: config.apiKey,
            events: [event],
            notifier: notifier
        )

        return try jsonEncoder.encode(payload)
    }

    @discardableResult
    public func report(
        _ error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String: CustomDebugStringConvertible],
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column,
        on req: Request
    ) -> Future<Void> {
        guard config.shouldReport else {
            return req.future()
        }

        return Future.flatMap(on: req) {
            let body = try self.buildBody(
                req,
                error: error,
                severity: severity,
                userId: userId,
                metadata: metadata,
                stacktrace: BugsnagStacktrace(
                    file: file,
                    method: function,
                    lineNumber: line,
                    columnNumber: column
                )
            )

            return self
                .sendReport(self.hostName, self.headers, body, req)
                .do { response in
                    if self.config.debug {
                        print("Bugsnag response:")
                        print(response.status.code, response.status.reasonPhrase)
                    }
                }
                .transform(to: ())
        }
    }
}
