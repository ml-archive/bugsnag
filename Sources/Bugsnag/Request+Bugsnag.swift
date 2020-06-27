import Vapor

extension Request {
    /// Bugsnag helper. Used to send reports during route handling.
    ///
    ///     // Report an error.
    ///     req.bugsnag.report(someError)
    ///
    public var bugsnag: Bugsnag {
        .init(request: self)
    }

    /// Bugsnag helper. Used to send reports during route handling.
    ///
    ///     // Report an error.
    ///     req.bugsnag.report(someError)
    ///
    public struct Bugsnag {
        public let request: Request
    }
}

extension Request.Bugsnag {
    /// Adds a breadcrumb to all reports sent.
    ///
    ///     req.bugsnag.breadcrumb("login", type: .user)
    ///
    /// - parameters:
    ///     - name: Unique identifier for this breadcrumb.
    ///     - type: Type of breadcrumb. 
    ///     - metadata: Optional context dictionary.
    @discardableResult
    public func breadcrumb(
        name: String,
        type: BugsnagBreadcrumbType,
        metadata: [String: CustomDebugStringConvertible] = [:]
    ) -> Request.Bugsnag {
        var meta: [String: String] = [:]
        meta.reserveCapacity(metadata.count)

        for (key, value) in metadata {
            meta[key] = value.debugDescription
        }

        let breadcrumb = BugsnagPayload.Event.Breadcrumb(
            metaData: meta,
            name: name,
            timestamp: ISO8601Timestamp.shared.current(),
            type: type.rawValue
        )

        self.breadcrumbs.append(breadcrumb)
        return self
    }

    private struct BreadcrumbsKey: StorageKey {
        typealias Value = [BugsnagPayload.Event.Breadcrumb]
    }

    var breadcrumbs: [BugsnagPayload.Event.Breadcrumb] {
        get {
            self.request.storage[BreadcrumbsKey.self] ?? .init()
        }
        nonmutating set {
            self.request.storage[BreadcrumbsKey.self] = newValue
        }
    }
}

extension Request.Bugsnag: BugsnagReporter {
    /// See `BugsnagReporter`.
    public var currentRequest: Request? {
        self.request
    }

    /// See `BugsnagReporter`.
    public var client: Client {
        self.request.client
    }

    /// See `BugsnagReporter`.
    public var logger: Logger {
        self.request.logger
    }

    /// See `BugsnagReporter`.
    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    /// See `BugsnagReporter`.
    public var configuration: BugsnagConfiguration? {
        self.request.application.bugsnag.configuration
    }

    /// See `BugsnagReporter`.
    public var users: BugsnagUsers {
        self.request.application.bugsnag.users
    }
}

/// Types of Bugsnag report breadcrumbs. 
public enum BugsnagBreadcrumbType: String {
    case error
    case log
    case manual
    case navigation
    case process
    case request
    case state
    case user
}
