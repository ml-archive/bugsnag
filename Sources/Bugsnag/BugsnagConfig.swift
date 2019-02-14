public struct BugsnagConfig {
    let apiKey: String
    let releaseStage: String
    let keyFilters: [String]
    let shouldReport: Bool
    let debug: Bool

    public init(
        apiKey: String,
        releaseStage: String,
        keyFilters: [String] = [],
        shouldReport: Bool = true,
        debug: Bool = false
    ) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
        self.keyFilters = keyFilters
        self.shouldReport = shouldReport
        self.debug = debug
    }
}
