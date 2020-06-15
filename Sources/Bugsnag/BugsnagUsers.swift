import Vapor

public struct BugsnagUsers {
    var storage: [(Request) -> (CustomStringConvertible?)]

    public mutating func add<User>(_ user: User.Type)
        where User: BugsnagUser & Authenticatable
    {
        self.storage.append({ request in
            request.auth.get(User.self)?.bugsnagID
        })
    }
}

public protocol BugsnagUser {
    var bugsnagID: CustomStringConvertible? { get }
}
