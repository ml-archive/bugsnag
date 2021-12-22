import Vapor

public protocol ReporterType {
    func report(error: Error, request: Request, userId: String?, userName: String?, userEmail: String?, skipContent: Bool, lineNumber: Int?, funcName: String?, fileName: String?, version: String?) throws
    
    func report(error: Error, request: Request, skipContent: Bool, lineNumber: Int?, funcName: String?, fileName: String?, version: String?) throws
    
    func report(
        error: Error,
        request: Request,
        severity: Severity,
        userId: String?,
        userName: String?,
        userEmail: String?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        version: String?,
        skipContent: Bool,
        completion: (() -> ())?
    ) throws
}

public enum Severity: String {
    case error, warning, info
}

public final class Bugsnag: ReporterType {
    public func report(error: Error, request: Request, userId: String?, userName: String?, userEmail: String?, skipContent: Bool, lineNumber: Int?, funcName: String?, fileName: String?, version: String?) throws {
        report(error: error, request: request, severity: .error, userId: userId, userName: userName, userEmail: userEmail, lineNumber: lineNumber, funcName: funcName, fileName: fileName, version: version, skipContent: skipContent, completion: nil)
    }
    
    
    let environment: Environment
    let notifyReleaseStages: [Environment]?
    let connectionManager: ConnectionManager
    let payloadTransformer: PayloadTransformerType
    
    public init(
        environment: Environment,
        notifyReleaseStages: [Environment]? = [],
        connectionManager: ConnectionManager,
        transformer: PayloadTransformerType
    ) {
        self.environment = environment
        self.notifyReleaseStages = notifyReleaseStages
        self.connectionManager = connectionManager
        self.payloadTransformer = transformer
    }

    public func report(error: Error, request: Request, skipContent: Bool, lineNumber: Int?, funcName: String?, fileName: String?, version: String?) {
        report(error: error, request: request, severity: .error, userId: nil, userName: nil, userEmail: nil, lineNumber: lineNumber, funcName: funcName, fileName: fileName, version: version, skipContent: skipContent, completion: nil)
    }
    
    public func report(
        error: Error,
        request: Request,
        severity: Severity = .error,
        userId: String?,
        userName: String?,
        userEmail: String?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        version: String?,
        skipContent: Bool,
        completion complete: (() -> ())?
    ) {
        guard let error = error as? AbortError else {
            report(
                message: "Internal Server Error",
                request: request,
                severity: severity,
                lineNumber: lineNumber,
                funcName: funcName,
                fileName: fileName,
                userId: userId,
                userName: userName,
                userEmail: userEmail,
                version: version,
                skipContent: skipContent,
                completion: complete
            )
            
            return
        }

        guard shouldNotifyForReleaseStage() else {
            return complete?() ?? ()
        }

        report(
            message: error.reason,
            request: request,
            severity: severity,
            lineNumber: lineNumber,
            funcName: funcName,
            fileName: fileName,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            version: version,
            skipContent: skipContent,
            completion: complete
        )
    }
    
    // MARK: - Private helpers

    private func report(
        message: String,
        request: Request,
        severity: Severity,
        lineNumber: Int? = nil,
        funcName: String? = nil,
        fileName: String? = nil,
        userId: String?,
        userName: String?,
        userEmail: String?,
        version: String?,
        skipContent: Bool,
        completion complete: (() -> ())? = nil
    ) {
        let payload = try? payloadTransformer.payloadFor(
            message: message,
            request: request,
            severity: severity,
            lineNumber: lineNumber,
            funcName: funcName,
            fileName: fileName,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            version: version,
            skipContent: skipContent
        )

        if let payload = payload {
            self.connectionManager.submitPayload(payload).whenComplete { _ in
                complete?()
            }
        }
    }

    private func shouldNotifyForReleaseStage() -> Bool {
        // If a user doesn't explicitly set this, report on all stages
        guard let notifyReleaseStages = notifyReleaseStages else {
            return true
        }
        
        return notifyReleaseStages.contains(environment)
    }
}
