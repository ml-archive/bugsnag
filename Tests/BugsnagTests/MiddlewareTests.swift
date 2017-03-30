import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class MiddlewareTests: XCTestCase {
    private var connectionManager: ConnectionManagerMock!
    private var middleware: Bugsnag.Middleware!
    private var reporter: ReporterMock!

    static let allTests = [
        ("testThatErrorsNotConformingToAbortErrorAreRethrown", testThatErrorsNotConformingToAbortErrorAreRethrown),
        ("testThatAbortErrorsAreRethrown", testThatAbortErrorsAreRethrown),
        ("testErrorNotConformingToAbortErrorWillBeReported", testErrorNotConformingToAbortErrorWillBeReported),
        ("testBadRequestAbortErrorWillBeReported", testBadRequestAbortErrorWillBeReported),
        ("testCustomErrorWillBeReported", testCustomErrorWillBeReported),
        ("testErrorNotReportedWhenExplicitlyToldNotTo", testErrorNotReportedWhenExplicitlyToldNotTo),
        ("testErrorReportedWhenExplicitlyToldSo", testErrorReportedWhenExplicitlyToldSo)
    ]

    override func setUp() {
        let drop = Droplet()
        let config = ConfigurationMock()
        self.reporter = ReporterMock(drop: drop, config: config)
        self.middleware = try! Bugsnag.Middleware(reporter: reporter)
    }

    override func tearDown() {
        self.connectionManager = nil
        self.middleware = nil
    }


    // MARK: Rethrowing.

    func testThatErrorsNotConformingToAbortErrorAreRethrown() {
        let next = ErrorResponderMock(error: MyCustomError())
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
        let error = MyCustomError()
        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertEqual(reporter.lastReport!.message, Status.internalServerError.reasonPhrase)
        XCTAssertEqual(reporter.lastReport!.metadata, nil)
        XCTAssertEqual(reporter.lastReport!.request.uri.description, req!.uri.description)
    }

    func testBadRequestAbortErrorWillBeReported() {
        let next = ErrorResponderMock(error: Abort.badRequest)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertEqual(reporter.lastReport!.message, Abort.badRequest.message)
        XCTAssertEqual(reporter.lastReport!.metadata, nil)
        XCTAssertEqual(reporter.lastReport!.request.uri.description, req!.uri.description)
    }

    func testCustomErrorWillBeReported() {
        let message = "My custom error"
        let code = 1337
        let status = Status.conflict
        let metadata: Node? = Node([
            "key1": "value1",
            "key2": "value2"
        ])
        let error = MyCustomAbortError(message: message, code: code, status: status, metadata: metadata)

        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertEqual(reporter.lastReport!.message, error.message)
        XCTAssertEqual(reporter.lastReport!.metadata, error.metadata)
        XCTAssertEqual(reporter.lastReport!.request.uri.description, req!.uri.description)
    }


    // MARK: Manual reporting.

    func testErrorNotReportedWhenExplicitlyToldNotTo() {
        let error = MyCustomAbortError(
            message: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": false])
        )

        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertNil(reporter.lastReport)
    }

    func testErrorReportedWhenExplicitlyToldSo() {
        let error = MyCustomAbortError(
            message: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": true])
        )

        let next = ErrorResponderMock(error: error)
        let req = try? Request(method: .get, uri: "some-random-uri")
        _ = try? middleware.respond(to: req!, chainingTo: next)

        XCTAssertNotNil(reporter.lastReport)
    }
}


// MARK: - Misc.

private struct MyCustomError: Error {}

private struct MyCustomAbortError: AbortError {
    let message: String
    let code: Int
    let status: Status
    let metadata: Node?
}
