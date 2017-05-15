import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class PayloadTransformerTests: XCTestCase {
    private var payloadTransformer: PayloadTransformer!
    private var payload: JSON!

    static let allTests = [
        ("testThatItUsesApiKeyFromConfig", testThatItUsesApiKeyFromConfig),
        ("testThatItBuildsErrorPayloadCorrectly", testThatItBuildsErrorPayloadCorrectly),
        ("testThatItBuildsAppPayloadCorrectly", testThatItBuildsAppPayloadCorrectly),
        ("testThatSeverityIsCorrect", testThatSeverityIsCorrect),
        ("testThatItHandlesCustomMetadata", testThatItHandlesCustomMetadata),
        ("testThatItBuildsNotifierPayloadCorrectly", testThatItBuildsNotifierPayloadCorrectly),
        ("testThatUrlParametersGetsFiltered", testThatUrlParametersGetsFiltered),
        ("testThatQueryParametersGetsFiltered", testThatQueryParametersGetsFiltered),
        ("testThatFormParametersGetsFiltered", testThatFormParametersGetsFiltered),
        ("testThatJsonParametersGetsFiltered", testThatJsonParametersGetsFiltered),
        ("testThatStackTraceSizeIsWorking", testThatStackTraceSizeIsWorking)
    ]

    override func setUp() {
        self.payloadTransformer = PayloadTransformer(
            frameAddress: FrameAddressMock.self,
            environment: .custom("mock-environment"),
            apiKey: "1337",
            defaultStackSize: 100,
            defaultFilters: []
        )
        
        let req = Request(method: .get, uri: "http://some-random-url.com/payload-test")
        req.parameters = ["url": "value"]
        req.query = ["query": "value"]
        req.formURLEncoded = ["form": "value"]
        req.json = JSON(node: Node(["json": "value"]))
        req.headers = ["Content-Type": "application/json"]
        self.payload = try! self.payloadTransformer.payloadFor(
            message: "Test message",
            metadata: Node(["key": "value"]),
            request: req,
            severity: .warning,
            stackTraceSize: 100,
            filters: []
        )
    }

    override func tearDown() {
        self.payloadTransformer = nil
    }


    func testThatItUsesApiKeyFromConfig() {
        XCTAssertEqual(payload["apiKey"]?.string, "1337")
    }

    func testThatItHandlesRequestPayloadCorrectly() {
        let request = payload["events"]?[0]?["metaData"]?["request"]
        let expectedHeaders = Node(["Content-Type": "application/json"])
        let expectedUrlParams = Node(["url": "value"])
        let expectedQueryParams = Node(["query": "value"])
        let expectedFormParams = Node(["form": "value"])
        let expectedJsonParams = Node(["json": "value"])

        XCTAssertEqual(request?["method"]?.string, "GET")
        XCTAssertEqual(request?["headers"]?.makeNode(in: nil), expectedHeaders)
        XCTAssertEqual(request?["urlParameters"]?.wrapped, expectedUrlParams.wrapped)
        XCTAssertEqual(request?["queryParameters"]?.wrapped, expectedQueryParams.wrapped)
        XCTAssertEqual(request?["formParameters"]?.wrapped, expectedFormParams.wrapped)
        XCTAssertEqual(request?["jsonParameters"]?.wrapped, expectedJsonParams.wrapped)
        XCTAssertEqual(request?["url"]?.string, "/payload-test")
    }

    func testThatItBuildsErrorPayloadCorrectly() {
        let event = payload["events"]?[0]

        XCTAssertEqual(event?["payloadVersion"]?.int, 2)
        XCTAssertEqual(event?["exceptions"]?[0]?["errorClass"]?.string, "Test message")
        XCTAssertEqual(event?["exceptions"]?[0]?["message"]?.string, "Test message")
    }

    func testThatItBuildsAppPayloadCorrectly() {
        let app = payload["events"]?[0]?["app"]

        XCTAssertEqual(app?["releaseStage"]?.string, "mock-environment")
        XCTAssertEqual(app?["type"]?.string, "Vapor")
    }

    func testThatSeverityIsCorrect() {
        XCTAssertEqual(payload["events"]?[0]?["severity"]?.string, Severity.warning.rawValue)
    }

    func testThatItHandlesCustomMetadata() {
        XCTAssertEqual(payload["events"]?[0]?["metaData"]?["metaData"]?["key"]?.string, "value")
    }

    func testThatItBuildsNotifierPayloadCorrectly() {
        let notifier = payload["notifier"]

        XCTAssertEqual(notifier?["name"]?.string, "Bugsnag Vapor")
        XCTAssertEqual(notifier?["version"]?.string, "1.0.11")
        XCTAssertEqual(notifier?["url"]?.string, "https://github.com/nodes-vapor/bugsnag")
    }

    func testThatUrlParametersGetsFiltered() {
        let req = Request(method: .get, uri: "http://some-random-url.com/payload-test")
        req.parameters = ["url": "value", "password": "1337", "mySecret": "lol"]
        let filters = ["password", "mySecret"]
        let payload = try! self.payloadTransformer.payloadFor(
            message: "",
            metadata: nil,
            request: req,
            severity: .error,
            stackTraceSize: 0,
            filters: filters
        )

        let urlParameters = payload["events"]?[0]?["metaData"]?["request"]?["urlParameters"]

        XCTAssertNil(urlParameters?["password"])
        XCTAssertNil(urlParameters?["mySecret"])
        XCTAssertEqual(urlParameters?["url"]?.string, "value")
    }

    func testThatQueryParametersGetsFiltered() {
        let req = Request(method: .get, uri: "http://some-random-url.com/payload-test")
        req.query = ["url": "value", "password": "1337", "mySecret": "lol"]
        let filters = ["password", "mySecret"]
        let payload = try! self.payloadTransformer.payloadFor(
            message: "",
            metadata: nil,
            request: req, severity: .error,
            stackTraceSize: 0,
            filters: filters
        )

        let urlParameters = payload["events"]?[0]?["metaData"]?["request"]?["queryParameters"]

        XCTAssertNil(urlParameters?["password"])
        XCTAssertNil(urlParameters?["mySecret"])
        XCTAssertEqual(urlParameters?["url"]?.string, "value")
    }

    func testThatFormParametersGetsFiltered() {
        let req = Request(method: .get, uri: "http://some-random-url.com/payload-test")
        req.formURLEncoded = ["url": "value", "password": "1337", "mySecret": "lol"]
        let filters = ["password", "mySecret"]
        let payload = try! self.payloadTransformer.payloadFor(
            message: "",
            metadata: nil,
            request: req,
            severity: .error,
            stackTraceSize: 0,
            filters: filters
        )

        let urlParameters = payload["events"]?[0]?["metaData"]?["request"]?["formParameters"]

        XCTAssertNil(urlParameters?["password"])
        XCTAssertNil(urlParameters?["mySecret"])
        XCTAssertEqual(urlParameters?["url"]?.string, "value")
    }

    func testThatJsonParametersGetsFiltered() {
        let req = Request(method: .get, uri: "http://some-random-url.com/payload-test")
        req.json = try! JSON(node:["url": "value", "password": "1337", "mySecret": "lol"])
        let filters = ["password", "mySecret"]
        let payload = try! self.payloadTransformer.payloadFor(
            message: "",
            metadata: nil,
            request: req,
            severity: .error,
            stackTraceSize: 0,
            filters: filters
        )

        let urlParameters = payload["events"]?[0]?["metaData"]?["request"]?["jsonParameters"]

        XCTAssertNil(urlParameters?["password"])
        XCTAssertNil(urlParameters?["mySecret"])
        XCTAssertEqual(urlParameters?["url"]?.string, "value")
    }

    func testThatStackTraceSizeIsWorking() {
        _ = try! payloadTransformer.payloadFor(
            message: "",
            metadata: nil,
            request: nil,
            severity: .error,
            stackTraceSize: 99,
            filters: []
        )
        XCTAssertEqual(FrameAddressMock.lastStackSize, 99)

    }
}
