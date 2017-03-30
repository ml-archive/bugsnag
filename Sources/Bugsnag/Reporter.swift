import Vapor
import HTTP
import Core

public protocol ReporterType {
    var drop: Droplet { get }
    var config: ConfigurationType { get }
    func report(message: String, metadata: Node?, request: Request) throws
    func report(
        message: String,
        metadata: Node?,
        request: Request,
        completion: (() -> ())?
    ) throws
}

public final class Reporter: ReporterType {
    public let drop: Droplet
    public let config: ConfigurationType
    let connectionManager: ConnectionManagerType
    let payloadTransformer: PayloadTransformerType

    init(
        drop: Droplet,
        config: ConfigurationType,
        connectionManager: ConnectionManagerType? = nil,
        transformer: PayloadTransformerType? = nil
    ) {
        self.drop = drop
        self.config = config
        self.connectionManager = connectionManager ?? ConnectionManager(
            drop: drop,
            config: config
        )
        self.payloadTransformer = transformer ?? PayloadTransformer(
            drop: drop,
            config: config
        )
    }

    public func report(
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

    public func report(
        message: String,
        metadata: Node?,
        request: Request,
        completion complete: (() -> ())? = nil
    ) throws {
        let payload = try payloadTransformer.payloadFor(
            message: message,
            metadata: metadata,
            request: request
        )

        // Fire and forget.
        // TODO: Consider queue and retry mechanism.
        try background {
            _ = try? self.connectionManager.submitPayload(payload)
            if let complete = complete { complete() }
        }
    }
}
