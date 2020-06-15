import Vapor

public struct BugsnagConfiguration {
    public var apiKey: String
    public var releaseStage: String
    /// A version identifier, (eg. a git hash)
    public var version: String?
    public var blockedKeys: Set<String>
    public var shouldReport: Bool

    public init(
        apiKey: String,
        releaseStage: String,
        version: String? = nil,
        blockedKeys: [String] = [],
        shouldReport: Bool = true
    ) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
        self.version = version
        self.blockedKeys = Set(blockedKeys)
        self.shouldReport = shouldReport
    }
}
