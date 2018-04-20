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
        return client.post(url, content: content)
    }
    
    // MARK: - Private helpers

    private func headers() -> HTTPHeaders {
        return HTTPHeaders([("Content-Type", "application/json")])
    }
}
