import Vapor

public struct BugsnagConfig: Service {
    let hostName: String
    let apiKey: String
    let payloadVersion: UInt8
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.hostName = "https://notify.bugsnag.com/"
        self.payloadVersion = 4
    }
}
