import Vapor
import Bugsnag
import HTTP

internal class ReporterMock: ReporterType {
    func report(error: Error, request: Request?) throws {
        try report(error: error, request: request, userId: nil, userName: nil, userEmail: nil)
    }
    
    func report(error: Error, request: Request?, userId: String?, userName: String?, userEmail: String?) throws {
        try report(error: error, request: request, severity: .error, stackTraceSize: nil, userId: userId, userName: userName, userEmail: userEmail, completion: nil)
    }
    
    var lastReport: (error: Error, request: Request?)? = nil

    internal func report(
        error: Error,
        request: Request?,
        severity: Severity,
        stackTraceSize: Int?,
        userId: String?,
        userName: String?,
        userEmail: String?,
        completion complete: (() -> ())?
    ) throws {
        self.lastReport = (error: error, request: request)
        if let complete = complete { complete() }
    }
}
