import Vapor
import HTTP
import Foundation
import Stacked


public protocol ConnectionManagerType {
    var drop: Droplet { get }
    var config: ConfigurationType { get }
    init(drop: Droplet, config: ConfigurationType)
    func submitPayload(_ json: JSON) throws -> Status
}

public final class ConnectionManager: ConnectionManagerType {
    public let drop: Droplet
    public let config: ConfigurationType
    
    public init(drop: Droplet, config: ConfigurationType) {
        self.drop = drop
        self.config = config
    }
    
    public func submitPayload(_ json: JSON) throws -> Status {
        let response = try drop.client.post(self.config.endpoint, headers: headers(), body: json.makeBody())
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
