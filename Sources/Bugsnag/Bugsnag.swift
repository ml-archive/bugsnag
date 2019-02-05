import Authentication
import Vapor

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

public final class BugsnagProvider: Provider {
    private let config: BugsnagConfig
    
    public init(config: BugsnagConfig) {
        self.config = config
    }

    public func register(_ services: inout Services) throws {
        services.register(BugsnagReporter(config: config))
        services.register { container in
            return BreadcrumbContainer()
        }
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}

public protocol BugsnagReportableUser: Authenticatable {
    var id: Int? { get }
}

struct BugsnagPayload: Encodable {
    let apiKey: String
    let events: [BugsnagEvent]
    let notifier: BugsnagNotifier
}

struct BugsnagNotifier: Encodable {
    let name: String
    let url: String
    let version: String
}

struct BugsnagEvent: Encodable {
    let app: BugsnagApp
    let breadcrumbs: [BugsnagBreadcrumb]
    let exceptions: [BugsnagException]
    let metaData: BugsnagMetaData
    let payloadVersion: String
    let request: BugsnagRequest
    let severity: String
    let unhandled: Bool
    let user: BugsnagUser?
}

struct BugsnagException: Encodable {
    let errorClass: String
    let message: String
    let stacktrace: [BugsnagStacktrace]
    let type: String
}

struct BugsnagBreadcrumb: Encodable {
    let metaData: BugsnagMetaData
    let name: String
    let timestamp: String
    let type: String
}

struct BugsnagRequest: Encodable {
    let body: String?
    let clientIp: String?
    let headers: [String: String]
    let httpMethod: String
    let referer: String
    let url: String

    init(httpRequest: HTTPRequest) {
        self.body = httpRequest.body.data.flatMap { String(data: $0, encoding: .utf8) }
        self.clientIp = httpRequest.remotePeer.hostname
        self.headers = Dictionary(httpRequest.headers.map { $0 }) { first, second in second }
        self.httpMethod = httpRequest.method.string
        self.referer = httpRequest.remotePeer.description
        self.url = httpRequest.urlString
    }
}

struct BugsnagThread: Encodable {
    let id: String
    let name: String
    let stacktrace: [BugsnagStacktrace]
    let type: String
}

struct BugsnagSeverityReason: Encodable {
    let attributes: [String]
    let type: String
}

struct BugsnagUser: Encodable {
    let id: String
}

struct BugsnagApp: Encodable {
    let releaseStage: String
}

struct BugsnagMetaData: Encodable {
    let meta: [String: String]
}

struct BugsnagStacktrace: Encodable {
    let file: String
    let method: String
    let lineNumber: Int
    let columnNumber: Int
    
    let code: [String] = []
    let inProject = true
}

struct BugsnagSession: Encodable {
    let events: [Int]
    let id: String
    let startedAt: String
}
