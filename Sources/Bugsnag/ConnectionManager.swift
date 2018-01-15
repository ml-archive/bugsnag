import Vapor
import HTTP
import Foundation

public protocol ConnectionManagerType {
    func submitPayload(_ json: JSON) throws -> Status
}

public final class ConnectionManager: ConnectionManagerType {
    public let client: ClientFactoryProtocol
    public let url: String
    
    public init(client: ClientFactoryProtocol, url: String) {
        self.client = client
        self.url = url
    }
    
    public func submitPayload(_ json: JSON) throws -> Status {
        let response = try client.post(url, query: [:], headers(), json.makeBody())
        return response.status
    }


    // MARK: - Private helpers

    private func headers() -> [HeaderKey: String] {
        let headers = [
            HeaderKey("Content-Type"): "application/json",
        ]
        
        return headers
    }
}
