import Vapor

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
public struct BugsnagUsers {
    var storage: [(Request) -> (type: String, id: CustomStringConvertible)?]

    public mutating func add<User>(_ user: User.Type)
        where User: BugsnagUser & Authenticatable
    {
        self.storage.append({ request in
            if let userID = request.auth.get(User.self)?.bugsnagID {
                return (String(describing: user), userID)
            }
            return nil
        })
    }
}

public protocol BugsnagUser {
    var bugsnagID: CustomStringConvertible? { get }
}
