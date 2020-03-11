import Vapor

extension Application {
    public var bugsnag: Bugsnag {
        .init(application: self)
    }

    public struct Bugsnag {
        public let application: Application
    }
}

extension Application.Bugsnag {
    private struct BugsnagConfigurationKey: StorageKey {
        typealias Value = BugsnagConfiguration
    }

    public var configuration: BugsnagConfiguration? {
        get {
            self.application.storage[BugsnagConfigurationKey.self]
        }
        nonmutating set {
            self.application.storage[BugsnagConfigurationKey.self] = newValue
        }
    }
}

extension Application.Bugsnag {
    private struct BugsnagUsersKey: StorageKey {
        typealias Value = BugsnagUsers
    }

    public var users: BugsnagUsers {
        get {
            self.application.storage[BugsnagUsersKey.self] ?? .init(storage: [])
        }
        nonmutating set {
            self.application.storage[BugsnagUsersKey.self] = newValue
        }
    }
}

extension Application.Bugsnag: BugsnagReporter {
    public var logger: Logger {
        self.application.logger
    }

    public var currentRequest: Request? {
        nil
    }

    public var client: Client {
        self.application.client
    }

    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }
}
