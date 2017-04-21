import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ConnectionManagerTests: XCTestCase {
    var client: ClientFactoryMock!
    var connectionManager: ConnectionManager!

    static let allTests = [
        ("testThatSubmitPayloadWorksProperly", testThatSubmitPayloadWorksProperly)
    ]

    override func setUp() {
        client = ClientFactoryMock()
        connectionManager = ConnectionManager(client: client, url: "http://userinfo@hostname.com/path?key=value#fragment")
    }

    override func tearDown() {
        client = nil
        connectionManager = nil
    }

    func testThatSubmitPayloadWorksProperly() {
        _ = try! connectionManager.submitPayload(JSON(node: ["my": "payload"]))
        XCTAssertEqual(client.lastRequest?.uri.scheme, "http")
        XCTAssertEqual(client.lastRequest?.uri.userInfo?.description, "userinfo")
        XCTAssertEqual(client.lastRequest?.uri.hostname, "hostname.com")
        XCTAssertEqual(client.lastRequest?.uri.path, "/path")
        XCTAssertEqual(client.lastRequest?.uri.query, "key=value")
        XCTAssertEqual(client.lastRequest?.uri.fragment, "fragment")
        XCTAssertEqual(client.lastRequest!.headers, [HeaderKey.contentType: "application/json"])
        XCTAssertEqual(client.lastRequest?.json, try! JSON(node: ["my": "payload"]))
    }



}
