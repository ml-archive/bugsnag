import Foundation
import Vapor
import HTTP

public protocol ConfigurationType {
    var apiKey: String { get }
    var notifyReleaseStages: [String]? { get }
    var endpoint: String { get }
    var filters: [String] { get }
    var stackTraceSize: Int { get }
    init(drop: Droplet) throws
}

public struct Configuration: ConfigurationType {
    static private let defaultStackTraceValue = 100

    public enum Field: String {
        case apiKey                 = "apiKey"
        case notifyReleaseStages    = "notifyReleaseStages"
        case endpoint               = "endpoint"
        case filters                = "filters"
        case stackTraceSize         = "stackTraceSize"

        var error: Abort {
            return Abort(
                .internalServerError,
                reason: "Bugsnag error - \(rawValue) config is missing."
            )
        }
    }
    
    public let apiKey: String
    public let notifyReleaseStages: [String]?
    public let endpoint: String
    public let filters: [String]
    public let stackTraceSize: Int

    public init(drop: Droplet) throws {
        // Set config
        guard let config: Config = drop.config["bugsnag"] else {
            throw Abort(
                .internalServerError,
                reason: "Bugsnag error - bugsnag.json config is missing."
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
        self.stackTraceSize = try Configuration.extract(
            field: .stackTraceSize,
            config: config
        ) ?? Configuration.defaultStackTraceValue
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

    private static func extract(
        field: Field,
        config: Config
    ) throws -> Int? {
        guard let size = config[field.rawValue]?.int else {
            return nil
        }
        return size
    }

}
