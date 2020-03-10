import Vapor

public protocol BugsnagReporter {
    var client: Client { get }
    var eventLoop: EventLoop { get }
    var configuration: BugsnagConfiguration? { get }
    var currentRequest: Request? { get }
    var users: BugsnagUsers { get }
}

extension BugsnagReporter {
    public func report(
        _ error: Error
    ) -> EventLoopFuture<Void> {
        guard let configuration = self.configuration else {
            fatalError("Bugsnag not configured, use app.bugsnag")
        }
        guard configuration.shouldReport else {
            return self.eventLoop.makeSucceededFuture(())
        }
        if let bugsnag = error as? BugsnagError, !bugsnag.shouldReport {
            return self.eventLoop.makeSucceededFuture(())
        }

        do {
            let payload = try self.buildPayload(
                configuration: configuration,
                error: error
            )

            let headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "Bugsnag-Api-Key": configuration.apiKey,
                "Bugsnag-Payload-Version": "4"
            ]

            return self.client.post("https://notify.bugsnag.com", headers: headers, beforeSend: { req in
                try req.content.encode(payload, as: .json)
            }).map { _ in
                // Ignore response.
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    private func buildPayload(
        configuration: BugsnagConfiguration,
        error: Error
    ) throws -> BugsnagPayload? {
        let breadcrumbs: [BugsnagPayload.Event.Breadcrumb]
        let eventRequest: BugsnagPayload.Event.Request?
        if let request = self.currentRequest {
            breadcrumbs = request.bugsnag.breadcrumbs
            eventRequest = .init(
                body: request.body.data.map {
                    String.init(decoding: $0.readableBytesView, as: UTF8.self )
                },
                clientIp: request.headers.forwarded?.for ?? request.remoteAddress?.hostname,
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
        if let abort = error as? AbortError, let source = abort.source {
            stacktrace = [.init(
                file: source.file,
                method: source.function,
                lineNumber: source.line,
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
