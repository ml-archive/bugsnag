import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ReporterTests: XCTestCase {
    private var connectionManager: ConnectionManagerMock!
    private var payloadTransformer: PayloadTransformerMock!
    private var reporter: ReporterType!

    static let allTests = [
        ("testErrorNotConformingToAbortErrorWillBeReported", testErrorNotConformingToAbortErrorWillBeReported),
        ("testBadRequestAbortErrorWillBeReported", testBadRequestAbortErrorWillBeReported),
        ("testCustomErrorWillBeReported", testCustomErrorWillBeReported),
        ("testErrorNotReportedWhenExplicitlyToldNotTo", testErrorNotReportedWhenExplicitlyToldNotTo),
        ("testErrorReportedWhenExplicitlyToldTo", testErrorReportedWhenExplicitlyToldTo),
        ("testThatThePayloadGetsSubmitted", testThatThePayloadGetsSubmitted)
    ]


    override func setUp() {
        let drop = Droplet()
        let config = ConfigurationMock()
        self.connectionManager = ConnectionManagerMock(drop: drop, config: config)
        self.payloadTransformer = PayloadTransformerMock(drop: drop, config: config)
        self.reporter = Reporter(
            drop: drop,
            config: config,
            connectionManager: self.connectionManager,
            transformer: self.payloadTransformer
        )
    }

    override func tearDown() {
        self.connectionManager = nil
        self.payloadTransformer = nil
        self.reporter = nil
    }


    // MARK: Automatic reporting.

    func testErrorNotConformingToAbortErrorWillBeReported() {
        let req = try! Request(method: .get, uri: "some-random-uri")

        try! reporter.report(error: MyCustomError(), request: req)

        XCTAssertEqual(payloadTransformer.lastPayloadData!.0, Status.internalServerError.reasonPhrase)
        XCTAssertNil(payloadTransformer.lastPayloadData!.1)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2?.method, req.method)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2?.uri.description, req.uri.description)
        XCTAssertNotNil(self.connectionManager.lastPayload)
    }

    func testBadRequestAbortErrorWillBeReported() {
        let req = try! Request(method: .get, uri: "some-random-uri")

        try! reporter.report(error: Abort.badRequest, request: req)

        XCTAssertEqual(payloadTransformer.lastPayloadData!.0, Abort.badRequest.message)
        XCTAssertNil(payloadTransformer.lastPayloadData!.1)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2?.method, req.method)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2?.uri.description, req.uri.description)
        XCTAssertNotNil(self.connectionManager.lastPayload)
    }

    func testCustomErrorWillBeReported() {
        let req = try! Request(method: .get, uri: "some-random-uri")
        let metadata: Node? = Node([
            "key1": "value1",
            "key2": "value2"
        ])
        let error = MyCustomAbortError(
            message: "Test message",
            code: 1337,
            status: .badRequest,
            metadata: metadata
        )

        try! reporter.report(error: error, request: req)

        XCTAssertEqual(payloadTransformer.lastPayloadData!.0, error.message)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.1, error.metadata)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2?.method, req.method)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2?.uri.description, req.uri.description)
        XCTAssertNotNil(self.connectionManager.lastPayload)
    }


    // MARK: - Manual reporting.

    func testErrorNotReportedWhenExplicitlyToldNotTo() {
        let req = try! Request(method: .get, uri: "some-random-uri")
        let error = MyCustomAbortError(
            message: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": false])
        )

        try! reporter.report(error: error, request: req)

        XCTAssertNil(payloadTransformer.lastPayloadData)
        XCTAssertNil(self.connectionManager.lastPayload)
    }

    func testErrorReportedWhenExplicitlyToldTo() {
        let req = try! Request(method: .get, uri: "some-random-uri")
        let error = MyCustomAbortError(
            message: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": true])
        )

        try! reporter.report(error: error, request: req)

        XCTAssertNotNil(payloadTransformer.lastPayloadData)
        XCTAssertNotNil(self.connectionManager.lastPayload)
    }


    // MARK: - Submission

    func testThatThePayloadGetsSubmitted() {
        let payloadExpectation = expectation(description: "Submit payload")

        let req = try! Request(method: .get, uri: "some-random-uri")
        try! reporter.report(
            error: Abort.badRequest,
            request: req,
            completion: {
                XCTAssertEqual(self.connectionManager.lastPayload, try! JSON(node: ["transformer": "mock"]))
                payloadExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }
}


// MARK: - Misc.

internal struct MyCustomError: Error {
    let value = 1337
}

internal struct MyCustomAbortError: AbortError {
    let message: String
    let code: Int
    let status: Status
    let metadata: Node?
}
