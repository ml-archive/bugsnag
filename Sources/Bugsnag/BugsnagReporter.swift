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

    public init(
        config: BugsnagConfig
    ) {
        self.config = config

        app = BugsnagApp(
            releaseStage: config.releaseStage
        )
        headers = .init([
            ("Content-Type", "application/json"),
            ("Bugsnag-Api-Key", config.apiKey),
            ("Bugsnag-Payload-Version", payloadVersion)
        ])
    }

    func buildBody(
        _ req: Request,
        error: Error,
        severity: String,
        userId: Int?,
        userMetadata: [String: CustomDebugStringConvertible],
        callsite: (file: String, function: String, line: Int, column: Int)
    ) throws -> LosslessHTTPBodyRepresentable {
        let abort = error as? AbortError
        let reason = abort?.reason ?? "Something went wrong"
        let status = abort?.status ?? .internalServerError

        let exception = BugsnagException(
            errorClass: error.localizedDescription,
            message: reason,
            stacktrace: [BugsnagStacktrace(
                file: callsite.file,
                method: callsite.function,
                lineNumber: callsite.line,
                columnNumber: callsite.column
            )],
            type: status.reasonPhrase
        )

        let breadcrumbs: [BugsnagBreadcrumb] = (try? req.privateContainer
            .make(BreadcrumbContainer.self))?
            .breadcrumbs ?? []

        let http = req.http

        let metadata = [
            "Error localized description": error.localizedDescription,
            "Request debug description": http.debugDescription
        ].merging(userMetadata.mapValues { $0.debugDescription }) { a, b in b }

        let event = BugsnagEvent(
            app: app,
            breadcrumbs: breadcrumbs,
            exceptions: [exception],
            metaData: BugsnagMetaData(meta: metadata),
            payloadVersion: payloadVersion,
            request: BugsnagRequest(httpRequest: http),
            severity: severity,
            unhandled: true,
            user: userId.map { BugsnagUser(id: "\($0)") }
        )

        let payload = BugsnagPayload(
            apiKey: config.apiKey,
            events: [event],
            notifier: notifier
        )

        return try jsonEncoder.encode(payload)
    }

    func report(
        severity: String,
        _ error: Error,
        userId: Int?,
        metadata: [String: CustomDebugStringConvertible],
        callsite: (file: String, function: String, line: Int, column: Int),
        on req: Request
    ) -> Future<Void> {
        guard config.shouldReport else {
            return req.future()
        }

        do {
            let body = try buildBody(
                req,
                error: error,
                severity: severity,
                userId: userId,
                userMetadata: metadata,
                callsite: callsite
            )

            return HTTPClient
                .connect(hostname: hostName, on: req)
                .flatMap(to: HTTPResponse.self) { client in
                    client.send(.init(method: .POST, url: "/", headers: self.headers, body: body))
                }
                .do { response in
                    if self.config.debug {
                        print("Bugsnag response:")
                        print(response.status.code, response.status.reasonPhrase)
                    }
                }
                .transform(to: ())
        } catch {
            // fail silently
        }

        return req.future()
    }

    @discardableResult
    public func info(
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) -> Future<Void> {
        return report(
            severity: "info",
            error,
            userId: nil,
            metadata: metadata,
            callsite: (file, function, line, column),
            on: req
        )
    }

    @discardableResult
    public func warning(
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) -> Future<Void> {
        return report(
            severity: "warning",
            error,
            userId: nil,
            metadata: metadata,
            callsite: (file, function, line, column),
            on: req
        )
    }

    @discardableResult
    public func error(
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) -> Future<Void> {
        return report(
            severity: "error",
            error,
            userId: nil,
            metadata: metadata,
            callsite: (file, function, line, column),
            on: req
        )
    }

    // MARK: Automatic user tracking

    @discardableResult
    public func info<U: BugsnagReportableUser>(
        userType: U.Type,
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) throws -> Future<Void> {
        let userId = try req.authenticated(userType)?.id

        return report(
            severity: "info",
            error,
            userId: userId,
            metadata: metadata,
            callsite: (file, function, line, column),
            on: req
        )
    }

    @discardableResult
    public func warning<U: BugsnagReportableUser>(
        userType: U.Type,
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) throws -> Future<Void> {
        let userId = try req.authenticated(userType)?.id

        return report(
            severity: "warning",
            error,
            userId: userId,
            metadata: metadata,
            callsite: (file, function, line, column),
            on: req
        )
    }

    @discardableResult
    public func error<U: BugsnagReportableUser>(
        userType: U.Type,
        _ error: Error,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) throws -> Future<Void> {
        let userId = try req.authenticated(userType)?.id

        return report(
            severity: "error",
            error,
            userId: userId,
            metadata: metadata,
            callsite: (file, function, line, column),
            on: req
        )
    }
}
