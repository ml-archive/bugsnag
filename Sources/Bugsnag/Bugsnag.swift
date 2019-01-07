import Vapor
import Authentication

public final class BugsnagProvider: Provider {
    let reporter: BugsnagReporter

    public init(apiKey: String, releaseStage: String, debug: Bool = false) {
        reporter = BugsnagReporter(apiKey: apiKey, releaseStage: releaseStage, debug: debug)
    }

    public func register(_ services: inout Services) throws {
        services.register(reporter)
        services.register { container in
            return BreadcrumbContainer()
        }
    }

    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return .done(on: container)
    }
}


public protocol BugsnagReportableUser: Authenticatable {
    var id: Int? { get }
}

struct BugsnagPayload: Encodable {
    let apiKey: String
    let notifier: BugsnagNotifier
    let events: [BugsnagEvent]
}

struct BugsnagNotifier: Encodable {
    let name: String
    let version: String
    let url: String
}

struct BugsnagEvent: Encodable {
    let payloadVersion: String
    let exceptions: [BugsnagException]
    let breadcrumbs: [BugsnagBreadcrumb]
    let request: BugsnagRequest
    let unhandled: Bool
    let severity: String
    let user: BugsnagUser?
    let app: BugsnagApp
    let metaData: BugsnagMetaData
}

struct BugsnagException: Encodable {
    let errorClass: String
    let message: String
    let stacktrace: [BugsnagStacktrace]
    let type: String
}

struct BugsnagBreadcrumb: Encodable {
    let timestamp: String
    let name: String
    let type: String
    let metaData: BugsnagMetaData
}

struct BugsnagRequest: Encodable {
    let clientIp: String?
    let headers: [String: String]?
    let httpMethod: String?
    let url: String?
    let referer: String?
    let body: String?
}

struct BugsnagThread: Encodable {
    let id: String
    let name: String
    let stacktrace: [BugsnagStacktrace]
    let type: String
}

struct BugsnagSeverityReason: Encodable {
    let type: String
    let attributes: [String]
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
    let lineNumber: Int
    let columnNumber: Int
    let method: String
    let inProject: Bool
    let code: [String]
}

struct BugsnagSession: Encodable {
    let id: String
    let startedAt: String
    let events: [Int]
}
