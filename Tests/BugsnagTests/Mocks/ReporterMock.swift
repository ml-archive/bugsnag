import Vapor
import Bugsnag
import HTTP

internal class ReporterMock: ReporterType {
    var lastReport: (error: Error, request: Request?)? = nil

    public func report(error: Error, request: Request?) throws {
        try report(error: error, request: request, severity: .error, stackTraceSize: nil, completion: nil)
    }

    internal func report(
        error: Error,
        request: Request?,
        severity: Severity,
        stackTraceSize: Int?,
        completion complete: (() -> ())?
    ) throws {
        self.lastReport = (error: error, request: request)
        if let complete = complete { complete() }
    }
}
