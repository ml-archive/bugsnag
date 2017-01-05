import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class BugsnagMiddlewareTests: XCTestCase {
    private var connectionManager: ConnectionManagerMock!
    private var middleware: BugsnagMiddleware!

    static var allTests : [(String, (BugsnagMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testThatErrorsNotConformingToAbortErrorAreRethrown", testThatErrorsNotConformingToAbortErrorAreRethrown),
            ("testThatAbortErrorsAreRethrown", testThatAbortErrorsAreRethrown),
            ("testErrorNotConformingToAbortErrorWillBeReported", testErrorNotConformingToAbortErrorWillBeReported),
            ("testBadRequestAbortErrorWillBeReported", testBadRequestAbortErrorWillBeReported),
            ("testCustomErrorWillBeReported", testCustomErrorWillBeReported),
            ("testErrorNotReportedWhenExplicitlyToldNotTo", testErrorNotReportedWhenExplicitlyToldNotTo),
            ("testErrorReportedWhenExplicitlyToldSo", testErrorReportedWhenExplicitlyToldSo)
        ]
    }

    override func setUp() {
        let drop = Droplet()
        let config = ConfigurationMock()
        self.connectionManager = ConnectionManagerMock(drop: drop, config: config)
        self.middleware = BugsnagMiddleware(connectionManager: connectionManager)
    }

    override func tearDown() {
        self.connectionManager = nil
        self.middleware = nil
    }


    // MARK: Rethrowing.

    func testThatErrorsNotConformingToAbortErrorAreRethrown() {
        let localizedErrorDescription = "Random test error"
        let next = ErrorResponderMock(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedErrorDescription]))
        let req = try? Request(method: .get, uri: "some-random-uri")

        do {
            _ = try middleware.respond(to: req!, chainingTo: next)
            XCTFail("Error not conforming to AbortError wasn't rethrown.")
        } catch {}
    }

    func testThatAbortErrorsAreRethrown() {
        let next = ErrorResponderMock(error: Abort.badRequest)
        let req = try? Request(method: .get, uri: "some-random-uri")

        do {
            _ = try middleware.respond(to: req!, chainingTo: next)
            XCTFail("Error conforming to AbortError wasn't rethrown.")
        } catch {}
    }


    // MARK: Automatic reporting.

    func testErrorNotConformingToAbortErrorWillBeReported() {
        let localizedErrorDescription = "Random test error"
        let next = ErrorResponderMock(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedErrorDescription]))
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertEqual(connectionManager.lastPost!.status, .internalServerError)
        XCTAssertEqual(connectionManager.lastPost!.message, localizedErrorDescription)
        XCTAssertEqual(connectionManager.lastPost!.metadata, nil)
        XCTAssertEqual(connectionManager.lastPost!.request.uri.description, req!.uri.description)
    }

    func testBadRequestAbortErrorWillBeReported() {
        let next = ErrorResponderMock(error: Abort.badRequest)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertEqual(connectionManager.lastPost!.status, .badRequest)
        XCTAssertEqual(connectionManager.lastPost!.message, Abort.badRequest.message)
        XCTAssertEqual(connectionManager.lastPost!.metadata, nil)
        XCTAssertEqual(connectionManager.lastPost!.request.uri.description, req!.uri.description)
    }

    func testCustomErrorWillBeReported() {
        let message = "My custom error"
        let code = 1337
        let status = Status.conflict
        let metadata: Node? = Node([
            "key1": "value1",
            "key2": "value2"
        ])
        let error = MyCustomError(message: message, code: code, status: status, metadata: metadata)

        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertEqual(connectionManager.lastPost!.status, error.status)
        XCTAssertEqual(connectionManager.lastPost!.message, error.message)
        XCTAssertEqual(connectionManager.lastPost!.metadata, error.metadata)
        XCTAssertEqual(connectionManager.lastPost!.request.uri.description, req!.uri.description)
    }


    // MARK: Manual reporting.

    func testErrorNotReportedWhenExplicitlyToldNotTo() {
        let error = MyCustomError(
            message: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": false])
        )

        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertNil(connectionManager.lastPost)
    }

    func testErrorReportedWhenExplicitlyToldSo() {
        let error = MyCustomError(
            message: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": true])
        )

        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertNotNil(connectionManager.lastPost)
    }
}


// MARK: - Misc.

private struct MyCustomError: AbortError {
    let message: String
    let code: Int
    let status: Status
    let metadata: Node?
}
