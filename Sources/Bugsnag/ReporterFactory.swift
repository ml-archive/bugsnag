import Vapor
import Stacked

public struct ReporterFactory {
    public static func make(config: Config) throws -> Reporter {
        guard let bConfig: Config = config["bugsnag"] else {
            throw Abort(
                .internalServerError,
                reason: "Bugsnag error - bugsnag.json config is missing."
            )
        }

        // NOTE: there is a bug in Vapor where extracted configs don't have the
        // same environment as the root config
        bConfig.environment = config.environment
        let bugsnagConfig = try BugsnagConfig(bConfig)

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
