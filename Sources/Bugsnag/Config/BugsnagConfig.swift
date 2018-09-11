import Vapor

public struct BugsnagConfig: Service {
    let hostName: String
    let apiKey: String
    let payloadVersion: UInt8
    let releaseStage: String
    let debug: Bool
    
    public init(apiKey: String, releaseStage: String, debug: Bool = false) {
        self.apiKey = apiKey
        self.hostName = "https://notify.bugsnag.com/"
        self.payloadVersion = 4
        self.releaseStage = releaseStage
        self.debug = debug
    }
}
