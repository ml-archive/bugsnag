import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ReporterTests: XCTestCase {
    private var connectionManager: ConnectionManagerMock!
    private var payloadTransformer: PayloadTransformerMock!
    private var reporter: Reporter!

    static let allTests = [
        ("testErrorNotConformingToAbortErrorWillBeReported", testErrorNotConformingToAbortErrorWillBeReported),
        ("testBadRequestAbortErrorWillBeReported", testBadRequestAbortErrorWillBeReported),
        ("testCustomErrorWillBeReported", testCustomErrorWillBeReported),
        ("testErrorNotReportedWhenExplicitlyToldNotTo", testErrorNotReportedWhenExplicitlyToldNotTo),
        ("testErrorReportedWhenExplicitlyToldTo", testErrorReportedWhenExplicitlyToldTo),
        ("testThatThePayloadGetsSubmitted", testThatThePayloadGetsSubmitted),
        ("testThatFiltersComeFromConfig", testThatFiltersComeFromConfig),
        ("testSeverityGetsDefaultValue", testSeverityGetsDefaultValue),
        ("testSeverityGetsGivenValue", testSeverityGetsGivenValue),
        ("testErrorNotReportedWhenEnvironmentNotInNotifyReleaseStages", testErrorNotReportedWhenEnvironmentNotInNotifyReleaseStages),
        ("testErrorReportedWhenEnvironmentInNotifyReleaseStages", testErrorReportedWhenEnvironmentInNotifyReleaseStages),
        ("testErrorNotBeingReportedWhenEmptyReleaseStages", testErrorNotBeingReportedWhenEmptyReleaseStages),
        ("testStackTraceSizeIsComingFromArguments", testStackTraceSizeIsComingFromArguments),
    ]

    override func setUp() {
        self.connectionManager = ConnectionManagerMock()
        
        self.payloadTransformer = PayloadTransformerMock(
            environment: .custom("mock-environment"),
            apiKey: "1337"
        )
        self.reporter = Reporter(
            environment: .custom("mock-environment"),
            notifyReleaseStages: ["mock-environment"],
            connectionManager: connectionManager,
            transformer: payloadTransformer,
            defaultStackSize: 100,
            defaultFilters: ["someFilter"]
        )
    }

    override func tearDown() {
        self.connectionManager = nil
        self.payloadTransformer = nil
        self.reporter = nil
    }


    // MARK: Automatic reporting.

    func testErrorNotConformingToAbortErrorWillBeReported() {
        let exp = expectation(description: "Custom abort error will be reported")

        let req = Request(method: .get, uri: "some-random-uri")
        reporter.report(
            error: MyCustomError(),
            request: req,
            severity: .error,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: {
                XCTAssertEqual(self.payloadTransformer.lastPayloadData!.0, Status.internalServerError.reasonPhrase)
                XCTAssertNil(self.payloadTransformer.lastPayloadData!.1)
                XCTAssertEqual(self.payloadTransformer.lastPayloadData!.2?.method, req.method)
                XCTAssertEqual(self.payloadTransformer.lastPayloadData!.2?.uri.description, req.uri.description)
                XCTAssertNotNil(self.connectionManager.lastPayload)
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    func testBadRequestAbortErrorWillBeReported() {
        let exp = expectation(description: "Bad request error will be reported")

        let req = Request(method: .get, uri: "some-random-uri")
        reporter.report(
            error: Abort.badRequest,
            request: req,
            severity: .error,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: {
                XCTAssertEqual(self.payloadTransformer.lastPayloadData!.0, Abort.badRequest.reason)
                XCTAssertNil(self.payloadTransformer.lastPayloadData!.1)
                XCTAssertEqual(self.payloadTransformer.lastPayloadData!.2?.method, req.method)
                XCTAssertEqual(self.payloadTransformer.lastPayloadData!.2?.uri.description, req.uri.description)
                XCTAssertNotNil(self.connectionManager.lastPayload)
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    func testCustomErrorWillBeReported() {
        let exp = expectation(description: "Custom error will be reported")

        let req = Request(method: .get, uri: "some-random-uri")
        let metadata: Node? = Node([
            "key1": "value1",
            "key2": "value2"
        ])
        let error = MyCustomAbortError(
            reason: "Test message",
            code: 1337,
            status: .badRequest,
            metadata: metadata
        )

        reporter.report(
            error: error,
            request: req,
            severity: .error,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: {
                XCTAssertEqual(self.payloadTransformer.lastPayloadData?.message, error.reason)
                XCTAssertEqual(self.payloadTransformer.lastPayloadData?.metadata?["key1"], error.metadata?["key1"])
                XCTAssertEqual(self.payloadTransformer.lastPayloadData?.metadata?["key2"], error.metadata?["key2"])
                XCTAssertEqual(self.payloadTransformer.lastPayloadData?.request?.method, req.method)
                XCTAssertEqual(self.payloadTransformer.lastPayloadData?.request?.uri.description, req.uri.description)
                XCTAssertNotNil(self.connectionManager.lastPayload)
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }


    // MARK: - Manual reporting.

    func testErrorNotReportedWhenExplicitlyToldNotTo() {
        let req = Request(method: .get, uri: "some-random-uri")
        let error = MyCustomAbortError(
            reason: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": false])
        )

        reporter.report(
            error: error,
            request: req,
            severity: .error,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: {
                XCTFail("Error reported when not supposed to.")
            }
        )

        XCTAssertNil(self.payloadTransformer.lastPayloadData)
        XCTAssertNil(self.connectionManager.lastPayload)
    }

    func testErrorReportedWhenExplicitlyToldTo() {
        let exp = expectation(description: "Error will be reported")

        let req = Request(method: .get, uri: "some-random-uri")
        let error = MyCustomAbortError(
            reason: "",
            code: 0,
            status: .accepted,
            metadata: Node(["report": true])
        )

        reporter.report(
            error: error,
            request: req,
            severity: .error,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: {
                XCTAssertNotNil(self.payloadTransformer.lastPayloadData)
                XCTAssertNotNil(self.connectionManager.lastPayload)
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }


    // MARK: - Filters.

    func testThatFiltersComeFromConfig() {
        let req = Request(method: .get, uri: "some-random-uri")

        reporter.report(
            error: Abort.badRequest,
            request: req,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: nil
        )
        
        XCTAssertEqual(self.payloadTransformer.lastPayloadData!.filters!, ["someFilter"])
    }


    // MARK: - Severity.

    func testSeverityGetsDefaultValue() {
        let req = Request(method: .get, uri: "some-random-uri")
        reporter.report(error: Abort.badRequest, request: req, userId: nil, userName: nil, userEmail: nil, completion: nil)
        XCTAssertEqual(self.payloadTransformer.lastPayloadData?.3, Severity.error)
    }

    func testSeverityGetsGivenValue() {
        let req = Request(method: .get, uri: "some-random-uri")
        reporter.report(error: Abort.badRequest, request: req,  severity: Severity.info, userId: nil, userName: nil, userEmail: nil,completion: nil)
        XCTAssertEqual(self.payloadTransformer.lastPayloadData?.3, Severity.info)
    }


    // MARK: - Notify release stages.
    func testErrorBeingReportedWhenNilReleaseStages() {
        let repo = Reporter(
            environment: .production,
            notifyReleaseStages: nil,
            connectionManager: self.connectionManager,
            transformer: self.payloadTransformer,
            defaultStackSize: 100
        )
        
        repo.report(error: Abort.badRequest, request: nil)
        XCTAssertNotNil(self.payloadTransformer.lastPayloadData)
    }
    
    
    func testErrorNotReportedWhenEnvironmentNotInNotifyReleaseStages() {
        //notifyReleaseStages = ["mock-environment"]
        let repo = Reporter(
            environment: .production,
            connectionManager: self.connectionManager,
            transformer: self.payloadTransformer,
            defaultStackSize: 100
        )
        repo.report(error: Abort.badRequest, request: nil)
        XCTAssertNil(self.payloadTransformer.lastPayloadData)
    }

    func testErrorReportedWhenEnvironmentInNotifyReleaseStages() {
        let repo = Reporter(
            environment: .custom("mock-environment"),
            notifyReleaseStages: ["mock-environment"],
            connectionManager: self.connectionManager,
            transformer: self.payloadTransformer,
            defaultStackSize: 100
        )
        repo.report(error: Abort.badRequest, request: nil)
        XCTAssertNotNil(self.payloadTransformer.lastPayloadData)
    }

    func testErrorNotBeingReportedWhenEmptyReleaseStages() {
        let repo = Reporter(
            environment: .custom("mock-environment"),
            connectionManager: self.connectionManager,
            transformer: self.payloadTransformer,
            defaultStackSize: 100
        )
        repo.report(error: Abort.badRequest, request: nil)
        XCTAssertNil(self.payloadTransformer.lastPayloadData)
    }


    // MARK: - Stack trace size.

    func testStackTraceSizeIsComingFromArguments() {
        let req = Request(method: .get, uri: "some-random-uri")
        reporter.report(error: Abort.badRequest, request: req, stackTraceSize: 150, userId: nil, userName: nil, userEmail: nil,completion: nil)
        XCTAssertEqual(self.payloadTransformer.lastPayloadData?.stackTraceSize, 150)
    }

    func testThatStackTraceSizeGetsDefaultValueWhenNotInConfig() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": ["mock-environment"],
            "endpoint": "some-endpoint",
            "filters": []
            ])
        let config = try! BugsnagConfig(conf)
        XCTAssertEqual(config.stackTraceSize, 100)
    }


    // MARK: - Submission

    func testThatThePayloadGetsSubmitted() {
        let exp = expectation(description: "Submit payload")

        let req = Request(method: .get, uri: "some-random-uri")
        reporter.report(
            error: Abort.badRequest,
            request: req,
            severity: .error,
            userId: nil,
            userName: nil,
            userEmail: nil,
            completion: {
                XCTAssertEqual(self.connectionManager.lastPayload, try! JSON(node: ["transformer": "mock"]))
                exp.fulfill()
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
    let reason: String
    let code: Int
    let status: Status
    let metadata: Node?
}
