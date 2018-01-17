import Vapor

public final class BugsnagProvider: Vapor.Provider {
    public static var repositoryName = "bugsnag"
    
    let environment: Environment
    let notifyReleaseStages: [String]?
    let apiKey: String
    
    public init(environment: Environment, notifyReleaseStages: [String]?, apiKey: String) {
        self.environment = environment
        self.notifyReleaseStages = notifyReleaseStages
        self.apiKey = apiKey
    }
    
    public func register(_ services: inout Services) throws {
        let payloadTransformer = PayloadTransformer(environment: environment, apiKey: apiKey)
        let connectionManager = ConnectionManager(url: "https://notify.bugsnag.com")
        
        let reporter = Reporter(environment: environment,
                 notifyReleaseStages: notifyReleaseStages,
                 connectionManager: connectionManager,
                 transformer: payloadTransformer)
        
        services.register(reporter)
    }
    
    public func boot(_ worker: Container) throws { }
}
