/// Errors conforming to this protocol have more control about how (or if) they will be reported.
public protocol ReportableError: Error {

    /// Whether to report this error (defaults to `true`)
    var shouldReport: Bool { get }

    /// Error severity (defaults to `.error`)
    var severity: Severity { get }

    /// The associated user id (if any) for the error (defaults to `nil`)
    var userId: CustomStringConvertible? { get }

    /// Any additional metadata (defaults to `[:]`)
    var metadata: [String: CustomDebugStringConvertible] { get }
}

public extension ReportableError {
    var shouldReport: Bool { return true }
    var severity: Severity { return .error }
    var userId: CustomStringConvertible? { return nil }
    var metadata: [String: CustomDebugStringConvertible] { return [:] }
}
