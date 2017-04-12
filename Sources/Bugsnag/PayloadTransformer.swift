import Vapor
import Stacked
import HTTP

public protocol PayloadTransformerType {
    var environment: Environment { get }
    var apiKey: String { get }

    func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        filters: [String]
    ) throws -> JSON
}

internal struct PayloadTransformer: PayloadTransformerType {
    let environment: Environment
    let apiKey: String

    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        filters: [String]
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
            "releaseStage": Node(environment.description),
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
                "urlParameters": filterOutKeys(filters, inNode: optionalNode(request?.parameters)),
                "queryParameters": filterOutKeys(filters, inNode: optionalNode(request?.query)),
                "formParameters": filterOutKeys(filters, inNode: optionalNode(request?.formURLEncoded)),
                "jsonParameters": filterOutKeys(filters, inNode: optionalNode(request?.json?.makeNode())),
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
            "apiKey": apiKey,
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

    private func filterOutKeys(_ keys: [String], inNode node: Node) -> Node {
        var outcome: [String: Node] = [:]

        guard let nodeObjects = node.nodeObject else {
            return node
        }

        for obj in nodeObjects {
            if !(keys.contains(obj.key)) {
                outcome[obj.key] = obj.value
            }
        }

        return Node.object(outcome)
    }
}
