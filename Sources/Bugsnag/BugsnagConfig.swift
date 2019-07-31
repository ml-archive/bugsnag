public struct BugsnagConfig {
    let apiKey: String
    let releaseStage: String
    /// A version identifier, (eg. a git hash)
    let version: String?
    let keyFilters: [String]
    let shouldReport: Bool
    let debug: Bool

    public init(
        apiKey: String,
        releaseStage: String,
        version: String? = nil,
        keyFilters: [String] = [],
        shouldReport: Bool = true,
        debug: Bool = false
    ) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
        self.version = version
        self.keyFilters = keyFilters
        self.shouldReport = shouldReport
        self.debug = debug
    }
}
