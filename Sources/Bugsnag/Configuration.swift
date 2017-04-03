import Foundation
import Vapor
import HTTP

public protocol ConfigurationType {
    var apiKey: String { get }
    var notifyReleaseStages: [String] { get }
    var endpoint: String { get }
    var filters: [String] { get }

    init(drop: Droplet) throws
}

public struct Configuration: ConfigurationType {
    
    public enum Field: String {
        case apiKey                 = "apiKey"
        case notifyReleaseStages    = "notifyReleaseStages"
        case endpoint               = "endpoint"
        case filters                = "filters"

        var error: Abort {
            return .custom(
                status: .internalServerError,
                message: "Bugsnag error - \(rawValue) config is missing."
            )
        }
    }
    
    public let apiKey: String
    public let notifyReleaseStages: [String]
    public let endpoint: String
    public let filters: [String]

    public init(drop: Droplet) throws {
        // Set config
        guard let config: Config = drop.config["bugsnag"] else {
            throw Abort.custom(
                status: .internalServerError,
                message: "Bugsnag error - bugsnag.json config is missing."
            )
        }
        
        try self.init(config: config)
    }

    public init(config: Config) throws {
        self.apiKey = try Configuration.extract(
            field: .apiKey,
            config: config
        )
        self.notifyReleaseStages = try Configuration.extract(
            field: .notifyReleaseStages,
            config: config
        )
        self.endpoint = try Configuration.extract(
            field: .endpoint,
            config: config
        )
        self.filters = try Configuration.extract(
            field: .filters,
            config: config
        )
    }
    
    private static func extract(
        field: Field,
        config: Config
    ) throws -> [String] {
        // Get array
        guard let platforms = config[field.rawValue]?.array else {
            throw field.error
        }
        
        // Get from config and make sure all values are strings
        return try platforms.map({
            guard let string = $0.string else {
                throw field.error
            }
            
            return string
        })
    }
    
    private static func extract(
        field: Field,
        config: Config
    ) throws -> String {
        guard let string = config[field.rawValue]?.string else {
            throw field.error
        }
        
        return string
    }
}
