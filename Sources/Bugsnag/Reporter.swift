import Vapor
import HTTP
import Core

public protocol ReporterType {
    func report(error: Error, request: Request?, userId: String?, userName: String?, userEmail: String?, lineNumber: Int?, funcName: String?, fileName: String?) throws
    
    func report(error: Error, request: Request?, lineNumber: Int?, funcName: String?, fileName: String?) throws
    
    func report(
        error: Error,
        request: Request?,
        severity: Severity,
        userId: String?,
        userName: String?,
        userEmail: String?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        completion: (() -> ())?
    ) throws
}

public enum Severity: String {
    case error, warning, info
}

public final class Reporter: ReporterType {
    public func report(error: Error, request: Request?, userId: String?, userName: String?, userEmail: String?, lineNumber: Int?, funcName: String?, fileName: String?) throws {
        report(error: error, request: request, severity: .error, userId: userId, userName: userName, userEmail: userEmail, lineNumber: lineNumber, funcName: funcName, fileName: fileName, completion: nil)
    }
    
    
    let environment: Environment
    let notifyReleaseStages: [String]?
    let connectionManager: ConnectionManagerType
    let payloadTransformer: PayloadTransformerType
    let defaultFilters: [String]
    
    init(
        environment: Environment,
        notifyReleaseStages: [String]? = [],
        connectionManager: ConnectionManagerType,
        transformer: PayloadTransformerType,
        defaultFilters: [String] = []
    ) {
        self.environment = environment
        self.notifyReleaseStages = notifyReleaseStages
        self.connectionManager = connectionManager
        self.payloadTransformer = transformer
        self.defaultFilters = defaultFilters
    }

    public func report(error: Error, request: Request?, lineNumber: Int?, funcName: String?, fileName: String?) {
        report(error: error, request: request, severity: .error, userId: nil, userName: nil, userEmail: nil, lineNumber: lineNumber, funcName: funcName, fileName: fileName, completion: nil)
    }
    
    public func report(
        error: Error,
        request: Request?,
        severity: Severity = .error,
        userId: String?,
        userName: String?,
        userEmail: String?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        completion complete: (() -> ())?
        ) {
        guard let error = error as? AbortError else {
            report(
                message: Status.internalServerError.reasonPhrase,
                metadata: nil,
                request: request,
                severity: severity,
                lineNumber: lineNumber,
                funcName: funcName,
                fileName: fileName,
                userId: userId,
                userName: userName,
                userEmail: userEmail,
                completion: complete
            )
            
            return
        }

        guard error.metadata?["report"]?.bool ?? true, shouldNotifyForReleaseStage() else {
            return
        }

        var metadata = error.metadata
        metadata?["host"] = Node(request?.uri.hostname ?? "")

        report(
            message: error.reason,
            metadata: metadata,
            request: request,
            severity: severity,
            lineNumber: lineNumber,
            funcName: funcName,
            fileName: fileName,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            completion: complete
        )
    }
    
    // MARK: - Private helpers

    private func report(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        lineNumber: Int? = nil,
        funcName: String? = nil,
        fileName: String? = nil,
        userId: String?,
        userName: String?,
        userEmail: String?,
        completion complete: (() -> ())? = nil
        ) {
        let payload = try? payloadTransformer.payloadFor(
            message: message,
            metadata: metadata,
            request: request,
            severity: severity,
            lineNumber: lineNumber,
            funcName: funcName,
            fileName: fileName,
            filters: defaultFilters,
            userId: userId,
            userName: userName,
            userEmail: userEmail
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
