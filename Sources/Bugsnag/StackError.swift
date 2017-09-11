import HTTP
import Vapor
import Stacked

public final class StacktraceError: AbortError {
    public let status: Status
    public let reason: String
    public let metadata: Node?

    public let line: UInt
    public let function: String
    public let file: String

    public let stacktrace: [String]

    public init(
        status: Status,
        reason: String,
        metadata: Node?,
        line: UInt = #line,
        function: String = #function,
        file: String = #file
    ) {
        self.status = status
        self.reason = reason
        self.metadata = metadata

        self.line = line
        self.function = function
        self.file = file

        stacktrace = FrameAddress.getStackTrace()
    }

    public static func badRequest(
        reason: String? = nil,
        metadata: Node? = nil,
        line: UInt = #line,
        function: String = #function,
        file: String = #file
    ) -> StacktraceError {
        let reason = reason ?? Status.badRequest.reasonPhrase
        return StacktraceError(
            status: .badRequest,
            reason: reason,
            metadata: metadata,
            line: line,
            function: function,
            file: file
        )
    }

    public static func serverError(
        reason: String? = nil,
        metadata: Node? = nil,
        line: UInt = #line,
        function: String = #function,
        file: String = #file
    ) -> StacktraceError {
        let reason = reason ?? Status.internalServerError.reasonPhrase
        return StacktraceError(
            status: .internalServerError,
            reason: reason,
            metadata: metadata,
            line: line,
            function: function,
            file: file
        )
    }

    public static func unauthorized(
        reason: String? = nil,
        metadata: Node? = nil,
        line: UInt = #line,
        function: String = #function,
        file: String = #file
    ) -> StacktraceError {
        let reason = reason ?? Status.unauthorized.reasonPhrase
        return StacktraceError(
            status: .unauthorized,
            reason: reason,
            metadata: metadata,
            line: line,
            function: function,
            file: file
        )
    }

    public static func notFound(
        reason: String? = nil,
        metadata: Node? = nil,
        line: UInt = #line,
        function: String = #function,
        file: String = #file
    ) -> StacktraceError {
        let reason = reason ?? Status.notFound.reasonPhrase
        return StacktraceError(
            status: .notFound,
            reason: reason,
            metadata: metadata,
            line: line,
            function: function,
            file: file
        )
    }
}
