import Foundation
import Vapor
import HTTP

public struct Configuration {
    
    public enum Field: String {
        case apiKey                 = "bugsnag.apiKey"
        case notifyReleaseStages    = "bugsnag.notifyReleaseStages"
        case endpoint               = "bugsnag.endpoint"
        case filters                = "bugsnag.filters"
        
        var path: [String] {
            return rawValue.components(separatedBy: ".")
        }
        
        var error: Abort {
            return .custom(status: .internalServerError,
                           message: "Bugsnag error - \(rawValue) config is missing.")
        }
    }
    
    public let apiKey: String
    public let notifyReleaseStages: [String]
    public let endpoint: String
    public let filters: [String]
    public init(drop: Droplet) throws {
        self.apiKey                 = try Configuration.extract(field: .apiKey, drop: drop)
        self.notifyReleaseStages    = try Configuration.extract(field: .notifyReleaseStages, drop: drop)
        self.endpoint               = try Configuration.extract(field: .endpoint, drop: drop)
        self.filters                = try Configuration.extract(field: .filters, drop: drop)
    }
    
    private static func extract(field: Field , drop: Droplet) throws -> [String] {
        // Get array
        guard let platforms = drop.config[field.path]?.array else {
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
    
    private static func extract(field: Field , drop: Droplet) throws -> String {
        guard let string = drop.config[field.path]?.string else {
            throw field.error
        }
        
        return string
    }
}
