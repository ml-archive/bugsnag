import Bugsnag
import XCTest
import Vapor

final class BugsnagTests: XCTestCase {
    func testSendReport() throws {
        var capturedSendReportParameters: (
            host: String,
            headers: HTTPHeaders,
            body: Data,
            container: Container
        )?

        let reporter = BugsnagReporter(
            config: .init(apiKey: "apiKey", releaseStage: "test"),
            sendReport: { host, headers, data, container in
                capturedSendReportParameters = (host, headers, data, container)
                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
            })
        let application = try Application.test()
        let request = Request(using: application)
        request.breadcrumb(name: "a", type: .log)

        _ = reporter
            .report(NotFound(), severity: .info, userId: 1, metadata: ["a": "b"], on: request)

        guard let params = capturedSendReportParameters else {
            XCTFail()
            return
        }

        XCTAssertEqual(params.host, "https://notify.bugsnag.com")
        XCTAssertEqual(params.headers["Content-Type"].first, "application/json")
        XCTAssertEqual(params.headers["Bugsnag-Api-Key"].first, "apiKey")
        XCTAssertEqual(params.headers["Bugsnag-Payload-Version"].first, "4")

        let payload = try JSONSerialization.jsonObject(with: params.body) as? [String: Any] ?? [:]
        print(payload)

        XCTAssertEqual(payload["apiKey"] as? String, "apiKey")
        let events = payload["events"] as? [[String: Any]]

        XCTAssertEqual(events?.count, 1)
    }

    func testReportingCanBeDisabled() throws {
        let reporter = BugsnagReporter(
            config: .init(apiKey: "apiKey", releaseStage: "test", shouldReport: false),
            sendReport: { host, headers, data, container in
                XCTFail("No error should be reported")
                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
        })

        let application = try Application.test()
        let request = Request(using: application)
        try reporter.report(NotFound(), on: request).wait()
    }
}
