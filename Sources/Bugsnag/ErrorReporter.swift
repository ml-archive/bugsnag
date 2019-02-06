import Vapor

public protocol ErrorReporter {
    @discardableResult
    func report(
        _ error: Error,
        severity: Severity,
        userId: Int?,
        metadata: [String: CustomDebugStringConvertible],
        file: String,
        function: String,
        line: Int,
        column: Int,
        on req: Request
    ) -> Future<Void>
}

extension ErrorReporter {
    @discardableResult
    func report(
        _ error: Error,
        severity: Severity = .error,
        userId: Int? = nil,
        metadata: [String: CustomDebugStringConvertible] = [:],
        on req: Request,
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
            on: req
        )
    }
}

