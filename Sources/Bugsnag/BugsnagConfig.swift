import Vapor

public struct BugsnagConfig {
    public enum Error: Swift.Error {
        case invalidConfig(field: String, Config)
    }
    
    public let apiKey: String
    public let notifyReleaseStages: [String]
    public let endpoint: String
    public let filters: [String]
    public let stackTraceSize: Int
    public let environment: Environment
    
    public init(_ config: Config) throws {
        apiKey = try config.get("apiKey")
        
        notifyReleaseStages = try config["notifyReleaseStages"]?.array?.map {
            guard let string = $0.string else {
                throw Error.invalidConfig(field: "notifyReleaseStages", config)
            }
            
            return string
        } ?? []
        
        endpoint = try config.get("endpoint")
        filters = try config["filters"]?.array?.map {
            guard let string = $0.string else {
                throw Error.invalidConfig(field: "filters", config)
            }
            
            return string
        } ?? []
        
        stackTraceSize = config["stackTraceSize"]?.int ?? 100
    
        environment = config.environment
    }
}
