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
    let notifyReleaseStages: [String]?
    let connectionManager: ConnectionManagerType
    let payloadTransformer: PayloadTransformerType
    let defaultStackSize: Int
    let defaultFilters: [String]
    
    init(
        environment: Environment,
        notifyReleaseStages: [String]? = [],
        connectionManager: ConnectionManagerType,
        transformer: PayloadTransformerType,
        defaultStackSize: Int,
        defaultFilters: [String] = []
    ) {
        self.environment = environment
        self.notifyReleaseStages = notifyReleaseStages
        self.connectionManager = connectionManager
        self.payloadTransformer = transformer
        self.defaultStackSize = defaultStackSize
        self.defaultFilters = defaultFilters
    }

    public func report(error: Error, request: Request?) {
        report(error: error, request: request, completion: nil)
    }

    public func report(
        error: Error,
        request: Request?,
        severity: Severity = .error,
        stackTraceSize: Int? = nil,
        completion complete: (() -> ())?
    ) {
        guard let error = error as? AbortError else {
            report(
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

        let stackError = error as? StacktraceError

        let stackTrace = stackError?.stacktrace
        let lineNumber = stackError?.line
        let funcName = stackError?.function
        let fileName = stackError?.file

        report(
            message: error.reason,
            metadata: error.metadata,
            request: request,
            severity: severity,
            stackTrace: stackTrace,
            lineNumber: lineNumber == nil ? nil : Int(lineNumber!),
            funcName: funcName,
            fileName: fileName,
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
        stackTrace: [String]? = nil,
        lineNumber: Int? = nil,
        funcName: String? = nil,
        fileName: String? = nil,
        stackTraceSize: Int?,
        completion complete: (() -> ())? = nil
    ) {
        let payload = try? payloadTransformer.payloadFor(
            message: message,
            metadata: metadata,
            request: request,
            severity: severity,
            stackTrace: stackTrace,
            lineNumber: lineNumber,
            funcName: funcName,
            fileName: fileName,
            stackTraceSize: stackTraceSize ?? defaultStackSize,
            filters: defaultFilters
        )

        // Fire and forget.
        // TODO: Consider queue and retry mechanism.

        if let payload = payload {
            background {
                _ = try? self.connectionManager.submitPayload(payload)
                if let complete = complete { complete() }
            }
        }
    }

    private func shouldNotifyForReleaseStage() -> Bool {
        // If a user doesn't explicitly set this, report on all stages
        guard let notifyReleaseStages = notifyReleaseStages else {
            return true
        }
        
        return notifyReleaseStages.contains(environment.description)
    }
}
