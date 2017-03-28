import Vapor
import HTTP
import Foundation
import Stacked


public protocol ConnectionManagerType {
    var drop: Droplet { get }
    var config: ConfigurationType { get }
    init(drop: Droplet, config: ConfigurationType)
    func post(status: Status, message: String, metadata: Node?, request: Request) throws -> Status
}

public final class ConnectionMananger: ConnectionManagerType {
    
    public let drop: Droplet
    public let config: ConfigurationType
    
    public init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }
    
    private func headers() -> [HeaderKey: String] {
        let headers = [
            HeaderKey("Content-Type"): "application/json",
        ]
        
        return headers
    }
    
    private func body(message: String, metadata: Node?, request: Request) throws -> JSON {
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

        let customMetaData = metadata ?? Node([])
        let metaData = Node([
            "request": Node([
                "method": Node(request.method.description),
                "headers": Node(headers),
                "params": request.parameters,
                "url": Node(request.uri.path)
            ]),
            "metaData": customMetaData
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
                "metaData": metaData
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
    
    private func post(json: JSON) throws -> Status {
        let response = try drop.client.post(self.config.endpoint, headers: headers(), body: json.makeBody())
        
        return response.status
    }
    
    public func post(status: Status, message: String, metadata: Node? = nil, request: Request) throws -> Status {
        return try post(json: body(message: message, metadata: metadata, request: request))
    }
    
}
