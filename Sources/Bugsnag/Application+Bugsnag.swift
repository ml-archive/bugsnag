import Vapor

extension Application {
    /// Bugsnag helper. Use to configure and send reports.
    ///
    ///     // Configure Bugsnag.
    ///     app.bugsnag.configuration = ...
    ///
    ///     // Report an error.
    ///     app.bugsnag.report(...)
    ///
    public var bugsnag: Bugsnag {
        .init(application: self)
    }

    /// Application's Bugsnag helper.
    public struct Bugsnag {
        /// The root application.
        public let application: Application
    }
}

extension Application.Bugsnag {
    private struct BugsnagConfigurationKey: StorageKey {
        typealias Value = BugsnagConfiguration
    }

    /// Configures Bugsnag for this application.
    ///
    /// This is usually set in `configure.swift`.
    ///
    ///     // Configure Bugsnag.
    ///     app.bugsnag.configuration = ...
    ///
    /// Must be set before accessing  Bugsnag helpers on `Application` and `Request`.
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

    /// Configures which users will be reported by Bugsnag.
    ///
    ///     // Adds TestUser to Bugsnag reports.
    ///     app.bugsnag.users.add(TestUser.self)
    ///
    /// User types must conform to `Authenticatable` and `BugsnagUser`.
    /// Configured user types will be automatically included in Bugsnag reports
    /// if they are logged in via the authentication API when reporting though `Request`.
    ///
    ///     // Logs in a user.
    ///     req.auth.login(TestUser())
    ///
    ///     // This error report will include the logged in
    ///     // user's identifier.
    ///     req.bugsnag.report(someError)
    ///
    /// Only one user can be included in a Bugsnag report.
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
    /// See `BugsnagReporter`.
    public var logger: Logger {
        self.application.logger
    }
    
    /// See `BugsnagReporter`.
    public var currentRequest: Request? {
        nil
    }
    
    /// See `BugsnagReporter`.
    public var client: Client {
        self.application.client
    }
    
    /// See `BugsnagReporter`.
    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }
}
