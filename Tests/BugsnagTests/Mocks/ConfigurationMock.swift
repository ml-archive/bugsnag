import Vapor
import Bugsnag

internal class ConfigurationMock: ConfigurationType {
    let apiKey = ""
    let notifyReleaseStages: [String] = []
    let endpoint = ""
    let filters: [String] = []

    required init(drop: Droplet) throws {}
    init() {}
}
