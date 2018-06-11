import Vapor

public struct BugsnagConfig: Service {
    let hostName: String
    let apiKey: String
    let payloadVersion: UInt8
    let releaseStage: String
    
    public init(apiKey: String, releaseStage: String) {
        self.apiKey = apiKey
        self.hostName = "https://notify.bugsnag.com/"
        self.payloadVersion = 4
        self.releaseStage = releaseStage
    }
}
