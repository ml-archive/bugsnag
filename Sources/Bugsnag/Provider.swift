import Vapor
import Stacked

public final class Provider: Vapor.Provider {

    public static var repositoryName = "Bugsnag"

    var config: BugsnagConfig
    
    public func boot(_ drop: Droplet) {
        let connectionManager = ConnectionManager(
            client: EngineClient.factory,
            url: config.endpoint
        )
        
        let transformer = PayloadTransformer(
            frameAddress: FrameAddress.self,
            environment: config.environment,
            apiKey: config.apiKey
        )
        
        let reporter = Reporter(
            environment: config.environment,
            notifyReleaseStages: config.notifyReleaseStages,
            connectionManager: connectionManager,
            transformer: transformer,
            defaultStackSize: config.stackTraceSize,
            defaultFilters: config.filters
        )
        
        drop.bugsnag = reporter
    }

    public func boot(_ config: Config) throws {
        guard let config: Config = config["bugsnag"] else {
            throw Abort(
                .internalServerError,
                reason: "Bugsnag error - bugsnag.json config is missing."
            )
        }
        
        self.config = try BugsnagConfig(config)
    }

    public init(config: Config) throws {
        guard let config: Config = config["bugsnag"] else {
            throw Abort(
                .internalServerError,
                reason: "Bugsnag error - bugsnag.json config is missing."
            )
        }
        
        self.config = try BugsnagConfig(config)
    }
    
    // is automatically called directly after boot()
    public func afterInit(_ drop: Droplet) {}
    
    // is automatically called directly after afterInit()
    public func beforeRun(_: Droplet) {}
    
    public func beforeServe(_: Droplet) {}
}
