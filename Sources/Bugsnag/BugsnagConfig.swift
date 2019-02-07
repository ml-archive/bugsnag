public struct BugsnagConfig {
    let apiKey: String
    let releaseStage: String
    let shouldReport: Bool
    let debug: Bool

    public init(
        apiKey: String,
        releaseStage: String,
        shouldReport: Bool = true,
        debug: Bool = false
    ) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
        self.shouldReport = shouldReport
        self.debug = debug
    }
}
