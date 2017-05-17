import Vapor

internal struct BugsnagConfig {
    internal let apiKey: String
    internal let notifyReleaseStages: [String]?
    internal let endpoint: String
    internal let filters: [String]
    internal let stackTraceSize: Int
    internal let environment: Environment
    
    internal init(_ config: Config) throws {
        apiKey = try config.get("apiKey")
        
        notifyReleaseStages = try config["notifyReleaseStages"]?.array?.map {
            guard let string = $0.string else {
                throw Abort(.internalServerError, reason: "Invalid field for: notifyReleaseStages")
            }
            
            return string
        }
        
        endpoint = try config.get("endpoint")
        filters = try config["filters"]?.array?.map {
            guard let string = $0.string else {
                throw Abort(.internalServerError, reason: "Invalid field for: filters")
            }
            
            return string
        } ?? []
        
        stackTraceSize = config["stackTraceSize"]?.int ?? 100
    
        environment = config.environment
    }
}
