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
        services.register(Bugsnag.self) { container -> Bugsnag in
            let payloadTransformer = PayloadTransformer(environment: self.environment, apiKey: self.apiKey)
            let client = try container.make(Client.self, for: Bugsnag.self)
            let connectionManager = ConnectionManager(url: "https://notify.bugsnag.com", client: client)
            
            let bugsnag = Bugsnag(environment: self.environment,
                                  notifyReleaseStages: self.notifyReleaseStages,
                                  connectionManager: connectionManager,
                                  transformer: payloadTransformer)
            
            return bugsnag
        }
    }
    
    public func boot(_ worker: Container) throws { }
}
