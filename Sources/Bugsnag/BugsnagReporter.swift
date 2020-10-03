import class Foundation.JSONSerialization
import Vapor

/// Capable of reporting Bugsnag errors.
///
/// See `req.bugsnag` and `app.bugsnag`.
public protocol BugsnagReporter {
    /// HTTP client used to contact Bugsnag.
    var client: Client { get }

    /// Logger to use for reporting information or errors.
    var logger: Logger { get }

    /// EventLoop to use for future returns.
    var eventLoop: EventLoop { get }

    /// Bugsnag configuration options for reporting.
    var configuration: BugsnagConfiguration? { get }

    /// Used to include additional information about the current
    /// request in the report. 
    var currentRequest: Request? { get }

    /// Configures which users will be reported by Bugsnag.
    var users: BugsnagUsers { get }
}

extension BugsnagReporter {
    /// Reports an error to Bugsnag.
    ///
    ///     req.bugsnag.report(someError)
    ///
    /// Conformance to `DebuggableError` and `BugsnagError` will be checked 
    /// for additional error context. 
    ///
    /// - parameters:
    ///     - error: The error to report. 
    @discardableResult
    public func report(
        _ error: Error
    ) -> EventLoopFuture<Void> {
        guard let configuration = self.configuration else {
            fatalError("Bugsnag not configured, set `app.bugsnag.configuration`.")
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
            let eventRequestBody: String?
            if let body = request.body.data {
                if !configuration.keyFilters.isEmpty {
                    let contentType = request.headers.contentType ?? .plainText
                    if let clean = self.cleaned(
                        body: body,
                        as: contentType,
                        keyFilters: configuration.keyFilters
                    ) {
                        eventRequestBody = clean
                    } else {
                        request.logger.warning("[Bugsnag] Could not clean request body of type \(contentType).")
                        request.logger.debug("[Bugsnag] Request bodies that cannot be cleaned will be hidden.")
                        eventRequestBody = "<hidden>"
                    }
                } else {
                    eventRequestBody = String(
                        decoding: body.readableBytesView,
                        as: UTF8.self
                    )
                }
            } else {
                eventRequestBody = nil
            }
            
            var headerDict: [String : Any] = request.headers.reduce([:], { result, value in
                var copy = result
                copy[value.0] = value.1
                return copy
            })
            strip(keys: configuration.keyFilters, from: &headerDict)

            let filteredHeaders: [(String, String)] = headerDict.map {
                k, v in (k, v as! String)
            }
            
            eventRequest = .init(
                body: eventRequestBody,
                clientIp: request.headers.forwarded.first(where: { $0.for != nil })?.for ?? request.remoteAddress?.hostname,
                headers: .init(uniqueKeysWithValues: filteredHeaders),
                httpMethod: request.method.string,
                referer: "n/a",
                url: request.url.string
            )
        } else {
            breadcrumbs = []
            eventRequest = nil
        }

        let exceptionStackTrace: [BugsnagPayload.Event.Exception.StackTrace]
        if
            let debuggable = error as? DebuggableError,
            let stackTrace = debuggable.stackTrace
        {
            exceptionStackTrace = stackTrace.frames.map { frame in
                .init(
                    file: frame.description,
                    method: frame.description,
                    lineNumber: 0,
                    columnNumber: 0
                )
            }
        } else if
            let debuggable = error as? DebuggableError,
            let source = debuggable.source
        {
            exceptionStackTrace = [.init(
                file: source.readableFile,
                method: source.function,
                lineNumber: Int(source.line),
                columnNumber: 0
            )]
        } else {
            exceptionStackTrace = []
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

        let message: String
        let type: String
        if let debuggable = error as? DebuggableError {
            message = debuggable.reason
            type = debuggable.fullIdentifier
        } else if let abort = error as? AbortError {
            message = abort.reason
            type = "AbortError.\(abort.status)"
        } else {
            message = "\(error)"
            type = "Swift.Error"
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
                            message: message,
                            stacktrace: exceptionStackTrace,
                            type: type
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

    private func cleaned(
        body: ByteBuffer,
        as contentType: HTTPMediaType,
        keyFilters: Set<String>
    ) -> String? {
        switch contentType {
        case .json, .jsonAPI:
            if var json = try? JSONSerialization.jsonObject(
                with: Data(body.readableBytesView)
            ) as? [String: Any] {
                self.strip(keys: keyFilters, from: &json)
                let data = try! JSONSerialization.data(withJSONObject: json)
                return String(decoding: data, as: UTF8.self)
            } else {
                fallthrough
            }
        default:
            return nil
        }
    }

    private func strip(keys: Set<String>, from data: inout [String: Any]) {
        for key in data.keys {
            if keys.contains(key) {
                data[key] = "<hidden>"
            } else {
                if var nested = data[key] as? [String: Any] {
                    self.strip(keys: keys, from: &nested)
                    data[key] = nested
                }
            }
        }
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
