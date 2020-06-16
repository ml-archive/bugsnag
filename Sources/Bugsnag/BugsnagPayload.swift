import Vapor

struct BugsnagPayload: Codable {
    let apiKey: String
    let events: [Event]

    struct Event: Codable {
        let app: Application

        struct Application: Codable {
            let releaseStage: String
            let version: String?
        }

        let breadcrumbs: [Breadcrumb]

        struct Breadcrumb: Codable {
            let metaData: [String: String]
            let name: String
            let timestamp: String
            let type: String
        }

        let exceptions: [Exception]

        struct Exception: Codable {
            let errorClass: String
            let message: String
            let stacktrace: [StackTrace]

            struct StackTrace: Codable {
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

        struct Request: Codable {
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

        struct User: Codable {
            let id: String
        }
    }

    let notifier: Notifier

    struct Notifier: Codable {
        let name: String
        let url: String
        let version: String
    }
}
