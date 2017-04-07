import Vapor
import Stacked
import HTTP

public protocol PayloadTransformerType {
    func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity
    ) throws -> JSON
}

internal struct PayloadTransformer: PayloadTransformerType {
    let drop: Droplet
    let config: ConfigurationType
    
    
    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity = Severity.error
    ) throws -> JSON {
        var code: [String: Node] = [:]
        
        var index = 0
        for entry in FrameAddress.getStackTrace() {
            code[String(index)] = Node(entry)
            
            index = index + 1
        }
        
        let stacktrace = Node([
            Node([
                "file": Node(message),
                "lineNumber": 0,
                "columnNumber": 0,
                "method": "NA",
                "code": Node(code)
            ])
        ])
   
        let app: Node = Node([
            "releaseStage": Node(drop.environment.description),
            "type": "Vapor"
        ])
        
        var headers: [String: Node] = [:]
        if let requestHeaders = request?.headers {
            for (key, value) in requestHeaders {
                headers[key.key] = Node(value)
            }
        }

        let customMetadata = metadata ?? Node([])
        let metadata = Node([
            "request": Node([
                "method": request != nil ? Node(request!.method.description) : Node.null,
                "headers": Node(headers),
                "urlParameters": optionalNode(request?.parameters),
                "queryParameters": optionalNode(request?.query),
                "formParameters": optionalNode(request?.formURLEncoded),
                "jsonParameters": optionalNode(request?.json?.makeNode()),
                "url": request != nil ? Node(request!.uri.path) : Node.null
            ]),
            "metaData": customMetadata
        ])

        let event: Node = Node([
            Node([
                "payloadVersion": 2,
                "exceptions": Node([
                    Node([
                        "errorClass": Node(message),
                        "message": Node(message),
                        "stacktrace": stacktrace
                    ])
                ]),
                "app": app,
                "severity": Node(severity.rawValue),
                "metaData": metadata
            ])
        ])
    
        return try JSON(node: [
            "apiKey": self.config.apiKey,
            "notifier": Node([
                "name": "Bugsnag Vapor",
                "version": "1.0.11",
                "url": "https://github.com/nodes-vapor/bugsnag"
            ]),
            "events": event,
        ])
    }


    // MARK: - Private helpers.

    private func optionalNode(_ node: Node?) -> Node {
        return node ?? Node.null
    }
}
