import Vapor

public final class Provider: Vapor.Provider {
    
    var config: ConfigurationType
    
    public func boot(_ drop: Droplet) {
        drop.bugsnag = Reporter(drop: drop, config: config)
    }
    
    public init(drop: Droplet) throws {
        config = try Configuration(drop: drop)
    }

    public init(config: Config) throws {
        guard let config: Config = config["bugsnag"] else {
            throw Abort.custom(
                status: .internalServerError,
                message: "Bugsnag error - bugsnag.json config is missing."
            )
        }
        
        self.config = try Configuration(config: config)
    }
    
    // is automatically called directly after boot()
    public func afterInit(_ drop: Droplet) {}
    
    // is automatically called directly after afterInit()
    public func beforeRun(_: Droplet) {}
    
    public func beforeServe(_: Droplet) {}
}
