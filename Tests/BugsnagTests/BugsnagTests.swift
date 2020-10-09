@testable import Bugsnag
import XCTVapor

final class BugsnagTests: XCTestCase {
    func testMiddleware() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.bugsnag.configuration = .init(
            apiKey: "foo",
            releaseStage: "debug"
        )
        app.clients.use(.test)
        app.middleware.use(BugsnagMiddleware())

        app.get("error") { req -> String in
            throw Abort(.internalServerError, reason: "Oops")
        }

        try app.test(.GET, "error") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }

        XCTAssertEqual(app.clients.test.requests[0].headers.first(name: "Bugsnag-Api-Key"), "foo")
        let payload = try app.clients.test.requests[0].content.decode(BugsnagPayload.self)
        XCTAssertEqual(payload.events[0].exceptions[0].message, "Oops")
    }

    func testBreadcrumbs() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.bugsnag.configuration = .init(
            apiKey: "foo",
            releaseStage: "debug"
        )
        app.clients.use(.test)
        app.get("error") { req -> HTTPStatus in
            req.bugsnag.breadcrumb(name: "bar", type: .state)
            req.bugsnag.report(Abort(.internalServerError, reason: "Oops"))
            return .ok
        }

        try app.test(.GET, "error") { res in
            XCTAssertEqual(res.status, .ok)
        }

        let payload = try app.clients.test.requests[0].content.decode(BugsnagPayload.self)
        XCTAssertEqual(payload.events[0].exceptions[0].message, "Oops")
        XCTAssertEqual(payload.events[0].breadcrumbs[0].name, "bar")
    }

    func testBlockedKeys() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.bugsnag.configuration = .init(
            apiKey: "foo",
            releaseStage: "debug",
            keyFilters: ["email", "password", "Authorization"]
        )
        app.clients.use(.test)

        final class User: Content {
            var name: String
            var email: String
            var password: String
            var user: User?

            init(name: String, email: String, password: String, user: User? = nil) {
                self.name = name
                self.email = email
                self.password = password
                self.user = user
            }
        }
        // Test reporting error with body.
        do {
            let vapor = User(
                name: "Vapor",
                email: "hello@vapor.codes",
                password: "swift-rulez-123",
                user: .init(
                    name: "Swift",
                    email: "hello@swift.org",
                    password: "super_secret"
                )
            )
            let request = Request(
                application: app,
                method: .POST,
                url: "/test",
                headers: [
                    "Authorization": "Bearer SupErSecretT0ken!"
                ], on: app.eventLoopGroup.next()
            )
            try request.content.encode(vapor)
            try request.bugsnag.report(Abort(.internalServerError, reason: "Oops")).wait()
        }

        // Check error has keys filtered out.
        do {
            let payload = try app.clients.test.requests[0].content.decode(BugsnagPayload.self)
            let user = try JSONDecoder().decode(
                User.self,
                from: Data(payload.events[0].request!.body!.utf8)
            )
            let headers = payload.events[0].request!.headers
            XCTAssertEqual(user.name, "Vapor")
            XCTAssertEqual(user.email, "<hidden>")
            XCTAssertEqual(user.password, "<hidden>")
            XCTAssertEqual(user.user?.name, "Swift")
            XCTAssertEqual(user.user?.email, "<hidden>")
            XCTAssertEqual(user.user?.password, "<hidden>")
            XCTAssertNil(user.user?.user)
            XCTAssertEqual(headers["Authorization"], "<hidden>")
        }
    }

    func testUsers() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.bugsnag.configuration = .init(
            apiKey: "foo",
            releaseStage: "debug"
        )
        app.bugsnag.users.add(TestUser.self)
        app.clients.use(.test)
        app.get("error") { req -> HTTPStatus in
            req.auth.login(TestUser(id: 123, name: "Vapor"))
            req.bugsnag.report(Abort(.internalServerError, reason: "Oops"))
            return .ok
        }

        try app.test(.GET, "error") { res in
            XCTAssertEqual(res.status, .ok)
        }

        let payload = try app.clients.test.requests[0].content.decode(BugsnagPayload.self)
        XCTAssertEqual(payload.events[0].user?.id, "123")
    }

    func testBugsnagError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.bugsnag.configuration = .init(
            apiKey: "foo",
            releaseStage: "debug"
        )
        app.bugsnag.users.add(TestUser.self)
        app.clients.use(.test)
        app.get("error") { req -> HTTPStatus in
            req.bugsnag.report(TestError())
            return .ok
        }

        try app.test(.GET, "error") { res in
            XCTAssertEqual(res.status, .ok)
        }

        let payload = try app.clients.test.requests[0].content.decode(BugsnagPayload.self)
        XCTAssertEqual(payload.events[0].metaData["foo"], "bar")
    }
}

struct TestError: BugsnagError {
    var metadata: [String : CustomStringConvertible] {
        ["foo": "bar"]
    }
}

struct TestUser: Authenticatable, BugsnagUser {
    let id: Int?
    let name: String

    var bugsnagID: CustomStringConvertible? {
        self.id
    }
}
