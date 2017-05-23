import Vapor
import Stacked

public struct ReporterFactory {
    public static func make(config: Config) throws -> Reporter {
        guard let config: Config = config["bugsnag"] else {
            throw Abort(
                .internalServerError,
                reason: "Bugsnag error - bugsnag.json config is missing."
            )
        }

        let bugsnagConfig = try BugsnagConfig(config)
        return ReporterFactory.make(bugsnagConfig: bugsnagConfig)
    }

    internal static func make(bugsnagConfig: BugsnagConfig) -> Reporter {
        let connectionManager = ConnectionManager(
            client: EngineClient.factory,
            url: bugsnagConfig.endpoint
        )
        
        let transformer = PayloadTransformer(
            frameAddress: FrameAddress.self,
            environment: bugsnagConfig.environment,
            apiKey: bugsnagConfig.apiKey
        )
        
        return Reporter(
            environment: bugsnagConfig.environment,
            notifyReleaseStages: bugsnagConfig.notifyReleaseStages,
            connectionManager: connectionManager,
            transformer: transformer,
            defaultStackSize: bugsnagConfig.stackTraceSize,
            defaultFilters: bugsnagConfig.filters
        )
    }
}
