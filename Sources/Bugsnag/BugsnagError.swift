/// Errors conforming to this protocol have more control about how (or if) they will be reported.
public protocol BugsnagError: Error {
    /// Whether to report this error (defaults to `true`)
    var shouldReport: Bool { get }

    /// Error severity (defaults to `.error`)
    var severity: BugsnagSeverity { get }

    /// Any additional metadata (defaults to `[:]`)
    var metadata: [String: CustomStringConvertible] { get }
}

public extension BugsnagError {
    var shouldReport: Bool { true }
    var severity: BugsnagSeverity { .error }
    var metadata: [String: CustomStringConvertible] { [:] }
}
