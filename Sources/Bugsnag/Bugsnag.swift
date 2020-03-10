import Vapor

public struct BugsnagPayload: Encodable {
    let apiKey: String
    let events: [Event]

    struct Event: Encodable {
        let app: Application

        struct Application: Encodable {
            let releaseStage: String
            let version: String?
        }

        let breadcrumbs: [Breadcrumb]

        struct Breadcrumb: Encodable {
            let metaData: [String: String]
            let name: String
            let timestamp: String
            let type: String
        }

        let exceptions: [Exception]

        struct Exception: Encodable {
            let errorClass: String
            let message: String
            let stacktrace: [Stacktrace]

            struct Stacktrace: Encodable {
                let file: String
                let method: String
                let lineNumber: Int
                let columnNumber: Int

                let code: [String] = []
                let inProject = true
            }

            let type: String
        }

        let metaData: [String: String]

        let payloadVersion: String
        let request: Request?

        struct Request: Encodable {
            let body: String?
            let clientIp: String?
            let headers: [String: String]
            let httpMethod: String
            let referer: String
            let url: String
        }


        let severity: String
        let unhandled = true
        let user: User?

        struct User: Encodable {
            let id: String
        }
    }

    let notifier: Notifier

    struct Notifier: Encodable {
        let name: String
        let url: String
        let version: String
    }
}
