import Vapor
import HTTP
import Foundation

public final class ConnectionManager {
    public let url: String
    
    public init(url: String) {
        self.url = url
    }
    
    public func submitPayload<C: Content>(_ content: C, request: Request) throws {
        let _ = try request.make(EngineClient.self).post(URI(url), content: content)
    }
    
    // MARK: - Private helpers

    private func headers() -> HTTPHeaders {
        return HTTPHeaders(dictionaryLiteral: (HTTPHeaders.Name.contentType, "application/json"))
    }
}
