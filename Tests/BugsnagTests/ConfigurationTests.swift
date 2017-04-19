import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ConfigurationTests: XCTestCase {
    static let allTests = [
        ("testThatNotifyReleaseStagesAcceptsNilValueInConfig", testThatNotifyReleaseStagesAcceptsNilValueInConfig)
    ]

    func testThatNotifyReleaseStagesAcceptsNilValueInConfig() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": nil,
            "endpoint": "some-endpoint",
            "filters": []
            ])
        let con = try! Configuration(config: conf)
        XCTAssertNil(con.notifyReleaseStages)
    }
}
