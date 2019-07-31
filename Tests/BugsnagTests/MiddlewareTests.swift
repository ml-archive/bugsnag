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

final class TestErrorReporter: ErrorReporter {

    var capturedReportParameters: (
        error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String: CustomDebugStringConvertible],
        file: String,
        function: String,
        line: Int,
        column: Int,
        container: Container
    )?
    func report(
        _ error: Error,
        severity: Severity,
        userId: CustomStringConvertible?,
        metadata: [String: CustomDebugStringConvertible],
        file: String,
        function: String,
        line: Int,
        column: Int,
        on container: Container
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
            container
        )
        return container.future()
    }
}

final class TestResponder: Responder {
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

final class MiddlewareTests: XCTestCase {
    var application: Application!
    var request: Request!
    var middleware: BugsnagMiddleware!

    let errorReporter = TestErrorReporter()
    let responder = TestResponder()

    override func setUp() {
        application = try! Application.test()
        request = Request(using: application)
        middleware = BugsnagMiddleware(reporter: errorReporter)
    }

    func testNoErrorReportedByDefault() throws {
        _ = try middleware.respond(to: request, chainingTo: responder).wait()

        // expect no error reported when response is successful
        XCTAssertNil(errorReporter.capturedReportParameters)
    }

    func testRespondErrorsAreCaptured() throws {
        responder.mockErrorToThrow = NotFound()

        _ = try? middleware.respond(to: request, chainingTo: responder).wait()

        // expect an error to be  reported when responder throws
        XCTAssertNotNil(errorReporter.capturedReportParameters)
    }

    func testErrorsInFutureAreCaptured() throws {
        errorReporter.capturedReportParameters = nil
        responder.mockErrorToReturnInFuture = NotFound()

        _ = try? middleware.respond(to: request, chainingTo: responder).wait()

        // expect an error to be reported when responder returns an errored future
        XCTAssertNotNil(errorReporter.capturedReportParameters)
    }

    func testReportableErrorPropertiesAreRespected() throws {
        struct MyError: ReportableError {
            let severity = Severity.info
            let userId: CustomStringConvertible? = 123
            let metadata: [String: CustomDebugStringConvertible] = ["meta": "data"]
        }

        let error = MyError()
        responder.mockErrorToThrow = error

        _ = try? middleware.respond(to: request, chainingTo: responder).wait()

        guard
            let params = errorReporter.capturedReportParameters
        else {
            XCTFail("No error was thrown")
            return
        }

        XCTAssertNotNil(params.error as? MyError)
        XCTAssertEqual(params.metadata as? [String: String], ["meta": "data"])
        XCTAssertEqual(params.severity.value, "info")
        XCTAssertEqual(params.userId as? Int, 123)
    }

    func testOptOutOfErrorReporting() throws {
        struct MyError: ReportableError {
            let shouldReport = false
        }

        responder.mockErrorToThrow = MyError()

        _ = try? middleware.respond(to: request, chainingTo: responder).wait()

        XCTAssertNil(errorReporter.capturedReportParameters)
    }
}
