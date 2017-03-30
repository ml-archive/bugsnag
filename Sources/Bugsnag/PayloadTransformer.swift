import Vapor
import Stacked
import HTTP

public protocol PayloadTransformerType {
    func payloadFor(message: String, metadata: Node?, request: Request) throws -> JSON
}

internal struct PayloadTransformer: PayloadTransformerType {
    let drop: Droplet
    let config: ConfigurationType

    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request
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
        for (key, value) in request.headers {
            headers[key.key] = Node(value)
        }

        let customMetadata = metadata ?? Node([])
        let metadata = Node([
            "request": Node([
                "method": Node(request.method.description),
                "headers": Node(headers),
                "params": request.parameters,
                "url": Node(request.uri.path)
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
                "severity": "error",
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
}
