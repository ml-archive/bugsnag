import Vapor

public protocol ErrorReporter {
    func report(
        _ error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String: CustomDebugStringConvertible],
        file: String,
        function: String,
        line: Int,
        column: Int,
        on container: Container
    ) -> Future<Void>
}

extension ErrorReporter {
    public func report(
        _ error: Error,
        severity: Severity = .error,
        userId: CustomStringConvertible? = nil,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on container: Container,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) -> Future<Void> {
        return report(
            error,
            severity: severity,
            userId: userId,
            metadata: metadata,
            file: file,
            function: function,
            line: line,
            column: column,
            on: container
        )
    }

    public func report<U: BugsnagReportableUser>(
        _ error: Error,
        severity: Severity = .error,
        userType: U.Type,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) -> Future<Void> {
        return Future.flatMap(on: req) {
            self.report(
                error,
                severity: severity,
                userId: try req.authenticated(U.self)?.id,
                metadata: metadata,
                file: file,
                function: function,
                line: line,
                column: column,
                on: req
            )
        }
    }
}
