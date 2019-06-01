import Vapor

final class BreadcrumbContainer: Service {
    var breadcrumbs: [BugsnagBreadcrumb] = []

    init() {}
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

extension Request {
    @discardableResult
    public func breadcrumb(
        name: String,
        type: BreadcrumbType,
        metadata: [String: CustomDebugStringConvertible] = [:]
    ) -> Request {
        do {
            let container = try privateContainer.make(BreadcrumbContainer.self)

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

            let breadcrumb = BugsnagBreadcrumb(
                metaData: meta,
                name: name,
                timestamp: date,
                type: type.rawValue
            )

            container.breadcrumbs.append(breadcrumb)
        } catch {
            // TODO: Figure out how we want to handle this error
        }

        return self
    }
}
