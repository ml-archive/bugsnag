import Vapor

public struct BugsnagPayload: Codable {
    public let apiKey: String
    public let events: [Event]

    public struct Event: Codable {
        public let app: Application

        public struct Application: Codable {
            public let releaseStage: String
            public let version: String?
        }

        public let breadcrumbs: [Breadcrumb]

        public struct Breadcrumb: Codable {
            public let metaData: [String: String]
            public let name: String
            public let timestamp: String
            public let type: String
        }

        public let exceptions: [Exception]

        public struct Exception: Codable {
            public let errorClass: String
            public let message: String
            public let stacktrace: [StackTrace]

            public struct StackTrace: Codable {
                public let file: String
                public let method: String
                public let lineNumber: Int
                public let columnNumber: Int

                public let code: [String] = []
                public let inProject = true
            }

            public let type: String
        }

        public let metaData: [String: String]

        public let payloadVersion: String
        public let request: Request?

        public struct Request: Codable {
            public let body: String?
            public let clientIp: String?
            public let headers: [String: String]
            public let httpMethod: String
            public let referer: String
            public let url: String
        }


        public let severity: String
        public let unhandled = true
        public let user: User?

        public struct User: Codable {
            public let id: String
        }
    }

    public let notifier: Notifier

    public struct Notifier: Codable {
        public let name: String
        public let url: String
        public let version: String
    }
}
