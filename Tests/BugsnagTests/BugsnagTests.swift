import Vapor
import XCTest
@testable import Bugsnag

extension Application {
    public static func test() throws -> Application {
        var services = Services()
        try services.register(BugsnagProvider(config: BugsnagConfig(
            apiKey: "e9792272fae71a3b869a1152008f7f0f",
            releaseStage: "development"
        )))

        var middlewaresConfig = MiddlewareConfig()
        middlewaresConfig.use(BugsnagMiddleware.self)
        services.register(middlewaresConfig)

        let sharedThreadPool = BlockingIOThreadPool(numberOfThreads: 2)
        sharedThreadPool.start()
        services.register(sharedThreadPool)

        return try Application(config: Config(), environment: .testing, services: services)
    }
}

private class TestErrorReporter: ErrorReporter {

    var capturedReportParameters: (
        error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String : CustomDebugStringConvertible],
        file: String,
        function: String,
        line: Int,
        column: Int,
        req: Request
    )?
    func report(
        _ error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String : CustomDebugStringConvertible],
        file: String,
        function: String,
        line: Int,
        column: Int,
        on req: Request
    ) -> Future<Void> {
        capturedReportParameters = (
            error,
            severity,
            userId,
            metadata,
            file,
            function,
            line,
            column,
            req
        )
        return req.future()
    }
}

private class TestResponder: Responder {
    var mockErrorToThrow: Error?
    var mockErrorToReturnInFuture: Error?
    func respond(to req: Request) throws -> Future<Response> {
        if let error = mockErrorToThrow {
            throw error
        } else if let error = mockErrorToReturnInFuture {
            return req.future(error: error)
        } else {
            return req.future(Response(using: req))
        }
    }
}

final class BugsnagTests: XCTestCase {
    func testMiddleware() throws {
        let application = try Application.test()
        let request = Request(using: application)
        let errorReporter = TestErrorReporter()
        let middleware = BugsnagMiddleware(reporter: errorReporter)
        let responder = TestResponder()
        _ = try middleware.respond(to: request, chainingTo: responder).wait()

        // expect no error reported when response is successful
        XCTAssertNil(errorReporter.capturedReportParameters)

        responder.mockErrorToThrow = NotFound()

        _ = try? middleware.respond(to: request, chainingTo: responder).wait()

        // expect an error to be  reported when responder throws
        XCTAssertNotNil(errorReporter.capturedReportParameters)

        errorReporter.capturedReportParameters = nil
        responder.mockErrorToReturnInFuture = NotFound()

        _ = try? middleware.respond(to: request, chainingTo: responder).wait()

        // expect an error to be reported when responder returns an errored future
        XCTAssertNotNil(errorReporter.capturedReportParameters)
    }

    func testSendReport() throws {
        var capturedSendReportParameters: (
            host: String,
            headers: HTTPHeaders,
            body: Data,
            request: Request
        )?

        let reporter = BugsnagReporter(
            config: .init(apiKey: "apiKey", releaseStage: "test"),
            sendReport: { host, headers, data, request in
                capturedSendReportParameters = (host, headers, data, request)
                return request.future(HTTPResponse(status: .ok))
        })
        let application = try Application.test()
        let request = Request(using: application)
        request.breadcrumb(name: "a", type: .log)

        reporter.report(NotFound(), severity: .info, userId: 1, metadata: ["a" : "b"], on: request)

        guard let params = capturedSendReportParameters else {
            XCTFail()
            return
        }

        XCTAssertEqual(params.host, "notify.bugsnag.com")
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
            sendReport: { host, headers, data, request in
                XCTFail("No error should be reported")
                return request.future(HTTPResponse(status: .ok))
        })

        let application = try Application.test()
        let request = Request(using: application)
        try reporter.report(NotFound(), on: request).wait()
    }
}
