import Vapor

public final class BreadcrumbContainer: Service {
    public var breadcrumbs: [BugsnagBreadcrumb] = []

    init() {}
}

public enum BreadcrumbType: String {
    case navigation
    case request
    case process
    case log
    case user
    case state
    case error
    case manual
}

extension Request {
    @discardableResult
    public func breadcrumb(
        name: String,
        type: BreadcrumbType,
        metadata: [String: CustomDebugStringConvertible] = [:]
    ) -> Request {
        do {
            let container = try make(BreadcrumbContainer.self)

            var meta: [String: String] = [:]
            meta.reserveCapacity(metadata.count)

            for (key, value) in metadata {
                meta[key] = value.debugDescription
            }

            // FIXME: DateFormatter is slooooooowwwwww on Linux
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

            let date = formatter.string(from: Date())

            let metadata = BugsnagMetaData(meta: meta)
            let breadcrumb = BugsnagBreadcrumb(
                timestamp: date,
                name: name,
                type: type.rawValue,
                metaData: metadata
            )

            container.breadcrumbs.append(breadcrumb)
        } catch {
            // TODO: Figure out how we want to handle this error
        }

        return self
    }
}
