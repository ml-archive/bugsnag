import Vapor
import Foundation

public final class ConnectionManager {
    public let url: String
    public let client: Client
    
    public init(url: String, client: Client) {
        self.url = url
        self.client = client
    }
    
    public func submitPayload<C: Content>(_ content: C) throws -> EventLoopFuture<ClientResponse> {
        return client.post(URI(string: url), headers: [:]) { req in
            try req.content.encode(content, as: .json)
        }
    }
}
