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
    
    public func submitPayload<C: Content>(_ content: C) throws {
        let _ = client.post(URI(url), content: content)
    }
    
    // MARK: - Private helpers

    private func headers() -> HTTPHeaders {
        return HTTPHeaders(dictionaryLiteral: (HTTPHeaders.Name.contentType, "application/json"))
    }
}
