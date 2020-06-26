/// Bugsnag's configuration options. 
///
///     app.bugsnag.configuration = .init(...)
///
public struct BugsnagConfiguration {
    /// Notifier API key found in Bugsnag project settings.
    public var apiKey: String

    /// Which version of your app is running, like `development` or `production`.
    public var releaseStage: String
    
    /// A version identifier, (eg. a git hash)
    public var version: String?

    /// Defines sensitive keys that should be hidden from data reported to Bugsnag.
    public var keyFilters: Set<String>

    /// Controls whether reports are sent to Bugsnag.
    public var shouldReport: Bool

    /// Creates a new `BugsnagConfiguration`.
    public init(
        apiKey: String,
        releaseStage: String,
        version: String? = nil,
        keyFilters: [String] = [],
        shouldReport: Bool = true
    ) {
        self.apiKey = apiKey
        self.releaseStage = releaseStage
        self.version = version
        self.keyFilters = Set(keyFilters)
        self.shouldReport = shouldReport
    }
}
