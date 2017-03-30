import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ReporterTests: XCTestCase {
    private var connectionManager: ConnectionManagerMock!
    private var payloadTransformer: PayloadTransformerMock!
    private var reporter: ReporterType!

    static let allTests = [
        ("testThatItUsesThePayloadTransformerToCreatePayload", testThatItUsesThePayloadTransformerToCreatePayload),
        ("testThatThePayloadGetsSubmitted", testThatThePayloadGetsSubmitted),
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


    func testThatItUsesThePayloadTransformerToCreatePayload() {
        let req = try! Request(method: .get, uri: "some-random-uri")
        let metadata: Node? = Node([
            "key1": "value1",
            "key2": "value2"
        ])
        let testData = ("Test message", metadata, req)

        try! reporter.report(
            message: testData.0,
            metadata: testData.1,
            request: testData.2
        )

        XCTAssertEqual(payloadTransformer.lastPayloadData!.0, testData.0)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.1, testData.1)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2.method, testData.2.method)
        XCTAssertEqual(payloadTransformer.lastPayloadData!.2.uri.description, testData.2.uri.description)
    }

    func testThatThePayloadGetsSubmitted() {
        let payloadExpectation = expectation(description: "Submit payload")

        let req = try! Request(method: .get, uri: "some-random-uri")
        // TODO: Runs on background thread - fix
        try! reporter.report(
            message: "",
            metadata: nil,
            request: req,
            completion: {
                XCTAssertEqual(self.connectionManager.lastPayload, try! JSON(node: ["transformer": "mock"]))
                payloadExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }
}
