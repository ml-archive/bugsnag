import Vapor
import HTTP
import Foundation

public final class ConnectionManager {
    public let url: String
    public let client: Client
    
    public init(url: String, client: Client) {
        self.url = url
        self.client = client
    }
    
    public func submitPayload<C: Content>(_ content: C) throws -> Future<Response> {
        return client.post(url, beforeSend: { req in
            try req.content.encode(content, as: .json)
        })
    }
}
