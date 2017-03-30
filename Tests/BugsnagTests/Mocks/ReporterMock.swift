import Vapor
import Bugsnag
import HTTP

internal class ReporterMock: ReporterType {
    let drop: Droplet
    let config: ConfigurationType
    var lastReport: (message: String, metadata: Node?, request: Request)? = nil

    required init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }

    internal func report(
        message: String,
        metadata: Node?,
        request: Request
    ) throws {
        try report(
            message: message,
            metadata: metadata,
            request: request,
            completion: nil
        )
    }

    internal func report(
        message: String,
        metadata: Node?,
        request: Request,
        completion complete: (() -> ())?
    ) throws {
        self.lastReport = (message: message, metadata: metadata, request: request)
        if let complete = complete { complete() }
    }
}
