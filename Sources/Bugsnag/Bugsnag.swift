import Authentication

public protocol BugsnagReportableUser: Authenticatable {
    associatedtype ID: CustomStringConvertible
    var id: ID? { get }
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
    let request: BugsnagRequest?
    let severity: String
    let unhandled = true
    let user: BugsnagUser?

    init(
        app: BugsnagApp,
        breadcrumbs: [BugsnagBreadcrumb],
        error: Error,
        httpRequest: HTTPRequest? = nil,
        keyFilters: [String],
        metadata: [String: CustomDebugStringConvertible],
        payloadVersion: String,
        severity: Severity,
        stacktrace: BugsnagStacktrace,
        userId: CustomStringConvertible?
    ) {
        self.app = app
        self.breadcrumbs = breadcrumbs
        self.exceptions = [BugsnagException(error: error, stacktrace: stacktrace)]
        self.metaData = BugsnagMetaData(
            meta: [
                "Error localized description": error.localizedDescription
            ].merging(metadata.mapValues { $0.debugDescription }) { a, b in b }
        )
        self.payloadVersion = payloadVersion
        self.request = httpRequest.map { BugsnagRequest(httpRequest: $0, keyFilters: keyFilters) }
        self.severity = severity.value
        self.user = userId.map { BugsnagUser(id: $0.description) }
    }
}

struct BugsnagException: Encodable {
    let errorClass: String
    let message: String
    let stacktrace: [BugsnagStacktrace]
    let type: String

    init(error: Error, stacktrace: BugsnagStacktrace) {
        let abort = error as? AbortError
        self.errorClass = error.localizedDescription
        self.message = abort?.reason ?? "Something went wrong"
        self.stacktrace = [stacktrace]
        self.type = (abort?.status ?? .internalServerError).reasonPhrase
    }
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

    init(httpRequest: HTTPRequest, keyFilters: [String]) {
        self.body = BugsnagRequest.filter(httpRequest.body, using: keyFilters)
        self.clientIp = httpRequest.remotePeer.hostname
        self.headers = Dictionary(httpRequest.headers.map { $0 }) { first, second in second }
        self.httpMethod = httpRequest.method.string
        self.referer = httpRequest.remotePeer.description
        self.url = httpRequest.urlString
    }

    static private func filter(_ body: HTTPBody, using filters: [String]) -> String? {
        guard
            let data = body.data,
            let unwrap = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let jsonObject = unwrap
        else {
            return body.data.flatMap { String(data: $0, encoding: .utf8) }
        }

        let filtered = jsonObject.filter { !filters.contains($0.key) }
        let json = try? JSONSerialization.data(withJSONObject: filtered, options: [.prettyPrinted])
        return json.flatMap { String(data: $0, encoding: .utf8) }
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
