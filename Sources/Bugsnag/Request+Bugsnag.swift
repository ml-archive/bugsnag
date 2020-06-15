import Vapor

extension Request {
    public var bugsnag: Bugsnag {
        .init(request: self)
    }

    public struct Bugsnag {
        public let request: Request
    }
}

extension Request.Bugsnag {
    @discardableResult
    public func breadcrumb(
        name: String,
        type: BreadcrumbType,
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
    public var currentRequest: Request? {
        self.request
    }

    public var client: Client {
        self.request.client
    }

    public var logger: Logger {
        self.request.logger
    }

    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    public var configuration: BugsnagConfiguration? {
        self.request.application.bugsnag.configuration
    }

    public var users: BugsnagUsers {
        self.request.application.bugsnag.users
    }
}

public enum BreadcrumbType: String {
    case error
    case log
    case manual
    case navigation
    case process
    case request
    case state
    case user
}
