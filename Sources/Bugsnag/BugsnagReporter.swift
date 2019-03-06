import Vapor

public struct BugsnagReporter: Service {
    private let app: BugsnagApp
    private let config: BugsnagConfig
    private let headers: HTTPHeaders

    private let hostName = "https://notify.bugsnag.com"
    private let jsonEncoder = JSONEncoder()
    private let notifier = BugsnagNotifier(
        name: "nodes-vapor/bugsnag",
        url: "https://github.com/nodes-vapor/bugsnag.git",
        version: "3"
    )
    private let payloadVersion = "4"
    private let sendReport: (String, HTTPHeaders, Data, Container) throws -> Future<Response>

    public init(
        config: BugsnagConfig,
        sendReport: ((String, HTTPHeaders, Data, Container) throws -> Future<Response>)? = nil
    ) {
        self.config = config

        self.sendReport = sendReport ?? { (hostName, headers, body, container) in
            try container
                .client()
                .post(hostName, headers: headers, beforeSend: { req in
                    req.http.body = .init(data: body)
                })
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
        _ container: Container,
        error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String: CustomDebugStringConvertible],
        stacktrace: BugsnagStacktrace
    ) throws -> Data {
        let req = container as? Request
        let breadcrumbsContainer = req?.privateContainer ?? container
        let breadcrumbs: [BugsnagBreadcrumb] = (try? breadcrumbsContainer
            .make(BreadcrumbContainer.self))?
            .breadcrumbs ?? []

        let event = BugsnagEvent(
            app: app,
            breadcrumbs: breadcrumbs,
            error: error,
            httpRequest: req?.http,
            keyFilters: config.keyFilters,
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

    public func report(
        _ error: Error,
        severity: Severity = .error,
        userId: CustomStringConvertible? = nil,
        metadata: [String: CustomDebugStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column,
        on container: Container
    ) -> Future<Void> {
        guard config.shouldReport else {
            return container.future()
        }

        return Future.flatMap(on: container) {
            let body = try self.buildBody(
                container,
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

            return try self
                .sendReport(self.hostName, self.headers, body, container)
                .do { response in
                    if self.config.debug {
                        let status = response.http.status
                        print("Bugsnag response:\n", status.code, status.reasonPhrase)
                    }
                }
                .transform(to: ())
        }
    }
}
