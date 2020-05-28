import Vapor

public protocol BugsnagReporter {
    var client: Client { get }
    var logger: Logger { get }
    var eventLoop: EventLoop { get }
    var configuration: BugsnagConfiguration? { get }
    var currentRequest: Request? { get }
    var users: BugsnagUsers { get }
}

extension BugsnagReporter {
    @discardableResult
    public func report(
        _ error: Error
    ) -> EventLoopFuture<Void> {
        guard let configuration = self.configuration else {
            fatalError("Bugsnag not configured, use app.bugsnag")
        }

        guard let payload = self.buildPayload(
            configuration: configuration,
            error: error
        ) else {
            return eventLoop.future(())
        }

        let headers: HTTPHeaders = [
            "Bugsnag-Api-Key": configuration.apiKey,
            "Bugsnag-Payload-Version": "4"
        ]

        return self.client.post("https://notify.bugsnag.com", headers: headers, beforeSend: { req in
            try req.content.encode(payload, as: .json)
        }).flatMapError { error -> EventLoopFuture<ClientResponse> in
            self.logger.report(error: error)
            return self.eventLoop.future(error: error)
        }.transform(to: ())
    }

    private func buildPayload(
        configuration: BugsnagConfiguration,
        error: Error
    ) -> BugsnagPayload? {
        guard configuration.shouldReport else {
            return nil
        }
        if let bugsnag = error as? BugsnagError, !bugsnag.shouldReport {
            return nil
        }
        
        let breadcrumbs: [BugsnagPayload.Event.Breadcrumb]
        let eventRequest: BugsnagPayload.Event.Request?
        if let request = self.currentRequest {
            breadcrumbs = request.bugsnag.breadcrumbs
            eventRequest = .init(
                body: request.body.data.map {
                    String(decoding: $0.readableBytesView, as: UTF8.self )
                },
                clientIp: request.headers.forwarded.first(where: { $0.for != nil })?.for ?? request.remoteAddress?.hostname,
                headers: .init(uniqueKeysWithValues: request.headers.map { $0 }),
                httpMethod: request.method.string,
                referer: "n/a",
                url: request.url.string
            )
        } else {
            breadcrumbs = []
            eventRequest = nil
        }

        let stacktrace: [BugsnagPayload.Event.Exception.Stacktrace]
        if let abort = error as? DebuggableError, let source = abort.source {
            stacktrace = [.init(
                file: source.readableFile,
                method: source.function,
                lineNumber: Int(source.line),
                columnNumber: 0
            )]
        } else {
            stacktrace = []
        }

        let metadata: [String: String]
        let severity: BugsnagSeverity

        if let bugsnag = error as? BugsnagError {
            metadata = bugsnag.metadata.mapValues { $0.description }
            severity = bugsnag.severity
        } else {
            metadata = [:]
            severity = .error
        }

        var userID: String?
        if let request = self.currentRequest {
            for closure in self.users.storage {
                userID = closure(request)?.description
            }
        }

        return BugsnagPayload(
            apiKey: configuration.apiKey,
            events: [
                BugsnagPayload.Event(
                    app: .init(
                        releaseStage: configuration.releaseStage,
                        version: configuration.version
                    ),
                    breadcrumbs: breadcrumbs,
                    exceptions: [
                        .init(
                            errorClass: "error",
                            message: "\(error)",
                            stacktrace: stacktrace,
                            type: "server"
                        )
                    ],
                    metaData: metadata,
                    payloadVersion: "4",
                    request: eventRequest,
                    severity: severity.value,
                    user: userID.map { .init(id: $0) }
                )
            ],
            notifier: .init(
                name: "nodes-vapor/bugsnag",
                url: "https://github.com/nodes-vapor/bugsnag.git",
                version: "3"
            )
        )
    }
}

extension ErrorSource {
    var readableFile: String {
        if self.file.contains("/Sources/") {
            return self.file.components(separatedBy: "/Sources/").last ?? self.file
        } else if self.file.contains("/Tests/") {
            return self.file.components(separatedBy: "/Tests/").last ?? self.file
        } else {
            return self.file
        }
    }
}
