import Vapor
import HTTP
import Core
import Stacked

public protocol ReporterType {
    func report(error: Error, request: Request?) throws
    
    func report(
        error: Error,
        request: Request?,
        severity: Severity,
        stackTraceSize: Int?,
        completion: (() -> ())?
    ) throws
}

public enum Severity: String {
    case error, warning, info
}

public final class Reporter: ReporterType {
    let environment: Environment
    let notifyReleaseStages: [String]
    let connectionManager: ConnectionManagerType
    let payloadTransformer: PayloadTransformerType
    
    init(
        environment: Environment,
        notifyReleaseStages: [String] = [],
        connectionManager: ConnectionManagerType,
        transformer: PayloadTransformerType
    ) {
        self.environment = environment
        self.notifyReleaseStages = notifyReleaseStages
        self.connectionManager = connectionManager
        self.payloadTransformer = transformer
    }

    public func report(error: Error, request: Request?) throws {
        try report(error: error, request: request, completion: nil)
    }

    public func report(
        error: Error,
        request: Request?,
        severity: Severity = .error,
        stackTraceSize: Int? = nil,
        completion complete: (() -> ())?
    ) throws {
        guard let error = error as? AbortError else {
            try report(
                message: Status.internalServerError.reasonPhrase,
                metadata: nil,
                request: request,
                severity: severity,
                stackTraceSize: stackTraceSize,
                completion: complete
            )
            
            return
        }
        
        guard error.metadata?["report"]?.bool ?? true, shouldNotifyForReleaseStage() else {
            return
        }
        
        try report(
            message: error.reason,
            metadata: error.metadata,
            request: request,
            severity: severity,
            stackTraceSize: stackTraceSize,
            completion: complete
        )
    }
    
    // MARK: - Private helpers

    private func report(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        stackTraceSize: Int?,
        completion complete: (() -> ())? = nil
    ) throws {
        let payload = try payloadTransformer.payloadFor(
            message: message,
            metadata: metadata,
            request: request,
            severity: severity,
            stackTraceSize: stackTraceSize,
            filters: nil
        )

        // Fire and forget.
        // TODO: Consider queue and retry mechanism.
        background {
            _ = try? self.connectionManager.submitPayload(payload)
            if let complete = complete { complete() }
        }
    }

    private func shouldNotifyForReleaseStage() -> Bool {
        return notifyReleaseStages.contains(environment.description)
    }
}
