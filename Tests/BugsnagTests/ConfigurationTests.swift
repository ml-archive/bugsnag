import XCTest
@testable import Vapor
@testable import Bugsnag
import HTTP

class ConfigurationTests: XCTestCase {
    static let allTests = [
        ("testThatDataExtractedCorrectlyFromConfigFile", testThatDataExtractedCorrectlyFromConfigFile),
        ("testThatErrorIsThrownWhenApiKeyNotInConfigFile", testThatErrorIsThrownWhenApiKeyNotInConfigFile),
        ("testThatErrorIsThrownWhenEndpointNotInConfigFile", testThatErrorIsThrownWhenEndpointNotInConfigFile),
        ("testThatErrorIsThrownWhenFiltersNotInConfigFile", testThatErrorIsThrownWhenFiltersNotInConfigFile),
        ("testDropInitIsWorkingCorrectly", testDropInitIsWorkingCorrectly),
        ("testThatErrorIsThrownWhenNoConfigFile", testThatErrorIsThrownWhenNoConfigFile),
        ("testThatNotifyReleaseStagesAcceptsNilValueInConfig", testThatNotifyReleaseStagesAcceptsNilValueInConfig),
        ("testThatStackTraceSizeGetsDefaultValueWhenNotInConfig", testThatStackTraceSizeGetsDefaultValueWhenNotInConfig)
    ]

    func testThatDataExtractedCorrectlyFromConfigFile(){
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": ["some-release-stage","other-release-stage"],
            "endpoint": "some-endpoint",
            "filters": ["some-filter", "another-filter"],
            "stackTraceSize": 99
            ])
        let con = try! Configuration(config: conf)
        XCTAssertEqual(con.apiKey, "1337")
        XCTAssertEqual(con.notifyReleaseStages!, ["some-release-stage","other-release-stage"])
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
            _ = try Configuration(config: conf)
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
            _ = try Configuration(config: conf)
            XCTFail("Error when endpoint not set wasn't thrown.")
        } catch {}
    }

    func testThatErrorIsThrownWhenFiltersNotInConfigFile() {
        let conf: Config = Config([
            "apiKey": "1337",
            "endpoint": "some-endpoint",
            "notifyReleaseStages": nil
            ])
        do {
            _ = try Configuration(config: conf)
            XCTFail("Error when filters not set wasn't thrown.")
        } catch {}
    }

    func testDropInitIsWorkingCorrectly() {
        let config = Config(["bugsnag": [
            "apiKey": "1337",
            "notifyReleaseStages": ["some-release-stage","other-release-stage"],
            "endpoint": "some-endpoint",
            "filters": ["some-filter", "another-filter"],
            "stackTraceSize": 99
            ]])
        let drop = Droplet(
            arguments: nil,
            workDir: nil,
            environment: nil,
            config: config,
            localization: nil,
            log: nil
        )
        let con = try! Configuration(drop: drop)

        XCTAssertEqual(con.apiKey, "1337")
        XCTAssertEqual(con.notifyReleaseStages!, ["some-release-stage","other-release-stage"])
        XCTAssertEqual(con.endpoint, "some-endpoint")
        XCTAssertEqual(con.filters, ["some-filter", "another-filter"])
        XCTAssertEqual(con.stackTraceSize, 99)
    }

    func testThatErrorIsThrownWhenNoConfigFile() {
        let drop = Droplet()
        do {
            _ = try Configuration(drop: drop)
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
        let con = try! Configuration(config: conf)
        XCTAssertNil(con.notifyReleaseStages)
    }

    func testThatStackTraceSizeGetsDefaultValueWhenNotInConfig() {
        let conf: Config = Config([
            "apiKey": "1337",
            "notifyReleaseStages": nil,
            "endpoint": "some-endpoint",
            "filters": []
            ])
        let config = try! Configuration(config: conf)
        XCTAssertEqual(config.stackTraceSize, 100)
    }
}
