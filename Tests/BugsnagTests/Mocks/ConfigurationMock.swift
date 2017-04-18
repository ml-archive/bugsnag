import Vapor
import Bugsnag

internal class ConfigurationMock: ConfigurationType {
    let apiKey = "1337"
    let notifyReleaseStages: [String]?
    let endpoint = "some-endpoint"
    let stackTraceSize = 1337
    let filters: [String] = ["someFilter"]

    required convenience init(drop: Droplet) throws {
        self.init()
    }

    init(releaseStages: [String]? = ["mock-environment"]) {
        notifyReleaseStages = releaseStages
    }
}
