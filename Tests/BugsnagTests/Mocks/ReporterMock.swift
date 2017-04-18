import Vapor
import Bugsnag
import HTTP

internal class ReporterMock: ReporterType {
    let drop: Droplet
    let config: ConfigurationType
    var lastReport: (error: Error, request: Request?)? = nil

    required init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }

    public func report(error: Error, request: Request?) throws {
        try report(error: error, request: request, severity: .error , stackTraceSize: nil, completion: nil)
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
