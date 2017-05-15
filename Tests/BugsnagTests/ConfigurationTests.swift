import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ConfigurationTests: XCTestCase {
    static let allTests = [
        ("testThatDataExtractedCorrectlyFromConfigFile", testThatDataExtractedCorrectlyFromConfigFile),
        ("testThatErrorIsThrownWhenApiKeyNotInConfigFile", testThatErrorIsThrownWhenApiKeyNotInConfigFile),
        ("testThatErrorIsThrownWhenEndpointNotInConfigFile", testThatErrorIsThrownWhenEndpointNotInConfigFile),
        ("testThatFiltersDefaultsToEmptyListWhenNotInConfigFile", testThatFiltersDefaultsToEmptyListWhenNotInConfigFile),
        ("testThatErrorIsThrownWhenNoConfigFile", testThatErrorIsThrownWhenNoConfigFile),
        ("testThatNotifyReleaseStagesAcceptsNilValueInConfig", testThatNotifyReleaseStagesAcceptsNilValueInConfig),
        ("testThatStackTraceSizeGetsDefaultValueWhenNotInConfig", testThatStackTraceSizeGetsDefaultValueWhenNotInConfig)
    ]

    func testThatDataExtractedCorrectlyFromConfigFile() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": ["some-release-stage","other-release-stage"],
            "endpoint": "some-endpoint",
            "filters": ["some-filter", "another-filter"],
            "stackTraceSize": 99
        ])
        let con = try! BugsnagConfig(conf)
        XCTAssertEqual(con.apiKey, "1337")
        XCTAssertEqual(con.notifyReleaseStages, ["some-release-stage","other-release-stage"])
        XCTAssertEqual(con.endpoint, "some-endpoint")
        XCTAssertEqual(con.filters, ["some-filter", "another-filter"])
        XCTAssertEqual(con.stackTraceSize, 99)
    }

    func testThatErrorIsThrownWhenApiKeyNotInConfigFile() {
        let conf: Config = Config([
            "notifyReleaseStages": nil,
            "endpoint": "some-endpoint",
            "filters": []
        ])
        do {
            _ = try BugsnagConfig(conf)
            XCTFail("Error when ApiKey not set wasn't thrown.")
        } catch {}
    }

    func testThatErrorIsThrownWhenEndpointNotInConfigFile() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": nil,
            "filters": []
            ])
        do {
            _ = try BugsnagConfig(conf)
            XCTFail("Error when endpoint not set wasn't thrown.")
        } catch {}
    }

    func testThatFiltersDefaultsToEmptyListWhenNotInConfigFile() {
        let conf: Config = Config([
            "apiKey": "1337",
            "endpoint": "some-endpoint",
            "notifyReleaseStages": nil
        ])
        do {
            let config = try BugsnagConfig(conf)
            XCTAssertEqual(config.filters, [])
        } catch {
            XCTFail("Error when filters not set was thrown. \(error)")
        }
    }

    func testThatErrorIsThrownWhenNoConfigFile() {
        let config = Config([:])
        do {
            _ = try BugsnagConfig(config)
            XCTFail("Error when config file not found wasn't thrown.")
        } catch {}
    }

    func testThatNotifyReleaseStagesAcceptsNilValueInConfig() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": nil,
            "endpoint": "some-endpoint",
            "filters": []
        ])
        let con = try! BugsnagConfig(conf)
        XCTAssert(con.notifyReleaseStages.isEmpty)
    }

    func testThatStackTraceSizeGetsDefaultValueWhenNotInConfig() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": nil,
            "endpoint": "some-endpoint",
            "filters": []
        ])
        let config = try! BugsnagConfig(conf)
        XCTAssertEqual(config.stackTraceSize, 100)
    }
}
