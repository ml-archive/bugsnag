import Async
import CodableKit
import Foundation
import Service

public final class BugsnagConfig: Service {
    let apiKey: String
    let notifyReleaseStages: [String]?
    let endpoint: String
    let environment: Environment
    
    init(apiKey: String, notifyReleaseStages: [String]?, endpoint: String, environment: Environment) {
        self.apiKey = apiKey
        self.notifyReleaseStages = notifyReleaseStages
        self.endpoint = endpoint
        self.environment = environment
    }
}
