import Vapor

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
    // let breadcrumbs: [BugsnagBreadcrumb]
    let request: BugsnagRequest
    // let threads: [BugsnagThread]
    // let context: String
    // let groupingHash: String
    // let unhandled: Bool
    // let severity: String
    // let severityReason: BugsnagSeverityReason
    // let user: BugsnagUser
    let app: BugsnagApp
    // let device: BugsnagDevice
    // let session: BugsnagSession
    let metaData: BugsnagMetaData
}

struct BugsnagException: Encodable {
    let errorClass: String
    let message: String
    // let stacktrace: [BugsnagStacktrace]
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
    let headers: [String:String]?
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
    let name: String
    let email: String
}

struct BugsnagApp: Encodable {
//    let id: String
//    let version: String
//    let versionCode: Int
//    let bundleVersion: String
//    let codeBundleId: String
//    let buildUUID: String
    let releaseStage: String
//    let type: String
//    let dsymUUIDs: [String]
//    let duration: UInt
//    let durationInForeground: UInt
//    let inForeground: Bool
}

struct BugsnagDevice: Encodable {
    let hostname: String
    let id: String
    let manufactorer: String
    let model: String
    let modelNumber: String
    let osName: String
    let osVersion: String
    let freeMemory: UInt
    let totalMemory: UInt
    let freeDisk: UInt
    let browserName: String
    let browserVersion: String
    let jailbroken: Bool
    let orientation: String
}

struct BugsnagMetaData: Encodable {
    let meta: [String:String]
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
