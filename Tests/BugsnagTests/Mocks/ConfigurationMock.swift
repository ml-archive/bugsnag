import Vapor
import Bugsnag

internal class ConfigurationMock: ConfigurationType {
    let apiKey = "1337"
    let notifyReleaseStages: [String]?
    let endpoint = "some-endpoint"
    let filters: [String] = ["someFilter"]

    required init(drop: Droplet) throws {
        notifyReleaseStages = []
    }
    init() {
        notifyReleaseStages = ["mock-environment"]
    }
    init(releaseStages: [String]?) {
        notifyReleaseStages = releaseStages
    }
}
