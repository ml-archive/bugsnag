import Vapor
import Stacked
import HTTP

public protocol PayloadTransformerType {
    var frameAddress: FrameAddressType.Type { get }
    var environment: Environment { get }
    var apiKey: String { get }

    func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        stackTrace: [String]?,
        lineNumber: Int?,
        funcName: String?,
        fileName: String?,
        stackTraceSize: Int,
        filters: [String]
    ) throws -> JSON
}

internal struct PayloadTransformer: PayloadTransformerType {
    let frameAddress: FrameAddressType.Type
    let environment: Environment
    let apiKey: String
    
    internal func payloadFor(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        stackTrace: [String]? = nil,
        lineNumber: Int? = nil,
        funcName: String? = nil,
        fileName: String? = nil,
        stackTraceSize: Int,
        filters: [String]
    ) throws -> JSON {
        var code: [String: Node] = [:]

        var index = 0
        for entry in stackTrace ?? frameAddress.getStackTrace(maxStackSize: stackTraceSize) {
            code[String(index)] = Node(entry)
            
            index = index + 1
        }
        
        let stacktrace = Node([
            Node([
                "file": Node((fileName ?? "") + ": " + message),
                "lineNumber": Node(lineNumber ?? 0),
                "columnNumber": 0,
                "method": Node(funcName ?? "NA"),
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
        
        var requestObj = Node.object([:])
        
        try requestObj.set("method", request?.method.description)
        try requestObj.set("headers", headers)
        try requestObj.set("urlParameters", filterOutKeys(filters, inNode: optionalNode(request?.parameters.makeNode(in: nil))))
        try requestObj.set("queryParameters", filterOutKeys(filters, inNode: optionalNode(request?.query)))
        try requestObj.set("formParameters", filterOutKeys(filters, inNode: optionalNode(request?.formURLEncoded)))
        try requestObj.set("jsonParameters", filterOutKeys(filters, inNode: optionalNode(request?.json?.makeNode(in: nil))))
        try requestObj.set("url", request?.uri.path)

        let metadata = Node([
            "request": requestObj,
            "metaData": customMetadata
        ])

        let event = Node([
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
    
        return try JSON(node: [
            "apiKey": apiKey,
            "notifier": Node([
                "name": "Bugsnag Vapor",
                "version": "1.0.11",
                "url": "https://github.com/nodes-vapor/bugsnag"
            ]),
            "events": Node([event]),
        ])
    }


    // MARK: - Private helpers.

    private func optionalNode(_ node: Node?) -> Node {
        return node ?? Node.null
    }

    private func filterOutKeys(_ keys: [String], inNode node: Node) -> Node {
        var outcome: [String: Node] = [:]

        guard let nodeObjects = node.object else {
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
