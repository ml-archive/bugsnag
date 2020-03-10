import Bugsnag
import XCTVapor

final class BugsnagTests: XCTestCase {
    func testSendReport() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.bugsnag.configuration = .init(
            apiKey: "36284374e946742a736737d7bc11344f",
            releaseStage: "debug"
        )

        app.middleware.use(BugsnagMiddleware())

        app.get("error") { req -> String in
            throw Abort(.internalServerError, reason: "Oops")
        }

        try app.test(.GET, "error") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }
}

//import Bugsnag
//import XCTest
//import Vapor
//
//final class BugsnagTests: XCTestCase {
//    func testSendReport() throws {
//        var capturedSendReportParameters: (
//            host: String,
//            headers: HTTPHeaders,
//            body: Data,
//            container: Container
//        )?
//
//        let reporter = BugsnagReporter(
//            config: .init(apiKey: "apiKey", releaseStage: "test"),
//            sendReport: { host, headers, data, container in
//                capturedSendReportParameters = (host, headers, data, container)
//                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
//            })
//        let application = try Application.test()
//        let request = Request(using: application)
//        request.breadcrumb(name: "a", type: .log)
//
//        _ = reporter
//            .report(NotFound(), severity: .info, userId: 1, metadata: ["a": "b"], on: request)
//
//        guard let params = capturedSendReportParameters else {
//            XCTFail()
//            return
//        }
//
//        XCTAssertEqual(params.host, "https://notify.bugsnag.com")
//        XCTAssertEqual(params.headers["Content-Type"].first, "application/json")
//        XCTAssertEqual(params.headers["Bugsnag-Api-Key"].first, "apiKey")
//        XCTAssertEqual(params.headers["Bugsnag-Payload-Version"].first, "4")
//
//        let payload = try JSONSerialization.jsonObject(with: params.body) as? [String: Any] ?? [:]
//        print(payload)
//
//        XCTAssertEqual(payload["apiKey"] as? String, "apiKey")
//        let events = payload["events"] as? [[String: Any]]
//
//        XCTAssertEqual(events?.count, 1)
//    }
//
//    func testReportingCanBeDisabled() throws {
//        let reporter = BugsnagReporter(
//            config: .init(apiKey: "apiKey", releaseStage: "test", shouldReport: false),
//            sendReport: { host, headers, data, container in
//                XCTFail("No error should be reported")
//                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
//        })
//
//        let application = try Application.test()
//        let request = Request(using: application)
//        try reporter.report(NotFound(), on: request).wait()
//    }
//
//    func testKeyFiltersWorkInRequestBody() throws {
//        var capturedSendReportParameters: (
//            host: String,
//            headers: HTTPHeaders,
//            body: Data,
//            container: Container
//        )?
//
//        let reporter = BugsnagReporter(
//            config: .init(apiKey: "apiKey", releaseStage: "test", keyFilters: ["password", "email"]),
//            sendReport: { host, headers, data, container in
//                capturedSendReportParameters = (host, headers, data, container)
//                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
//            })
//        let application = try Application.test()
//        let request = Request(using: application)
//        request.http.method = .POST
//        request.http.body = TestBody.default.httpBody
//
//        _ = try! reporter.report(NotFound(), on: request).wait()
//
//        guard let params = capturedSendReportParameters else {
//            XCTFail()
//            return
//        }
//
//        let responseBody = try JSONDecoder().decode(BugsnagResponseBody<TestBody>.self, from: params.body)
//
//        guard let body = responseBody.events.first?.request?.body else {
//            XCTFail("Unable to parse request body")
//            return
//        }
//        XCTAssertNil(body.password, "test that password is removed")
//        XCTAssertNil(body.email, "test that email is removed")
//        XCTAssertEqual(body.hash, TestBody.default.hash, "test that hash is not altered")
//    }
//
//    func testKeyFiltersWorkInHeaderFields() throws {
//        var capturedSendReportParameters: (
//            host: String,
//            headers: HTTPHeaders,
//            body: Data,
//            container: Container
//        )?
//
//        let reporter = BugsnagReporter(
//            config: .init(apiKey: "apiKey", releaseStage: "test", keyFilters: ["password", "email"]),
//            sendReport: { host, headers, data, container in
//                capturedSendReportParameters = (host, headers, data, container)
//                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
//            })
//        let application = try Application.test()
//        let request = Request(using: application)
//        request.http.method = .POST
//        request.http.body = TestBody.default.httpBody
//        var headers = request.http.headers
//        headers.add(name: HTTPHeaderName("password"), value: TestBody.default.password!)
//        headers.add(name: HTTPHeaderName("email"), value: TestBody.default.email!)
//        headers.add(name: HTTPHeaderName("hash"), value: TestBody.default.hash!)
//        request.http.headers = headers
//
//        _ = try! reporter.report(NotFound(), on: request).wait()
//
//        guard let params = capturedSendReportParameters else {
//            XCTFail()
//            return
//        }
//
//        let responseBody = try JSONDecoder().decode(BugsnagResponseBody<TestBody>.self, from: params.body)
//
//        guard let responseHeaders = responseBody.events.first?.request?.headers else {
//            XCTFail("Unable to parse response headers")
//            return
//        }
//
//        XCTAssertNil(responseHeaders["password"], "test that password is removed")
//        XCTAssertNil(responseHeaders["email"], "test that email is removed")
//        XCTAssertEqual(responseHeaders["hash"], TestBody.default.hash!, "test that hash is not altered")
//    }
//
//    func testKeyFiltersWorkInURLQueryParams() throws {
//        var capturedSendReportParameters: (
//            host: String,
//            headers: HTTPHeaders,
//            body: Data,
//            container: Container
//        )?
//
//        let reporter = BugsnagReporter(
//            config: .init(apiKey: "apiKey", releaseStage: "test", keyFilters: ["password", "email"]),
//            sendReport: { host, headers, data, container in
//                capturedSendReportParameters = (host, headers, data, container)
//                return container.future(Response(http: HTTPResponse(status: .ok), using: container))
//            })
//        let application = try Application.test()
//        let request = Request(using: application)
//        request.http.url = URL(string: "http://foo.bar.com/?password=\(TestBody.default.password!)&email=\(TestBody.default.email!)&hash=\(TestBody.default.hash!)")!
//        request.http.method = .POST
//        request.http.body = TestBody.default.httpBody
//        var headers = request.http.headers
//        headers.add(name: HTTPHeaderName("password"), value: TestBody.default.password!)
//        headers.add(name: HTTPHeaderName("email"), value: TestBody.default.email!)
//        headers.add(name: HTTPHeaderName("hash"), value: TestBody.default.hash!)
//        request.http.headers = headers
//
//        _ = try! reporter.report(NotFound(), on: request).wait()
//
//        guard let params = capturedSendReportParameters else {
//            XCTFail()
//            return
//        }
//
//        let responseBody = try JSONDecoder().decode(BugsnagResponseBody<TestBody>.self, from: params.body)
//
//        guard let responseURLString = responseBody.events.first?.request?.url else {
//            XCTFail("Unable to parse response url")
//            return
//        }
//
//        let urlComponents = URLComponents(string: responseURLString)
//        let passwordItem = urlComponents?.queryItems?.filter { $0.name == "password" }.last
//        let emailItem = urlComponents?.queryItems?.filter { $0.name == "email" }.last
//        let hashItem = urlComponents?.queryItems?.filter { $0.name == "hash" }.last
//
//        XCTAssertNil(passwordItem, "test that password is removed")
//        XCTAssertNil(emailItem, "test that email is removed")
//        XCTAssertEqual(hashItem?.value, TestBody.default.hash!, "test that hash is not altered")
//    }
//}
//
//struct TestBody: Codable {
//    var password: String?
//    var email: String?
//    var hash: String?
//
//    static var `default`: TestBody {
//        return .init(password: "TopSecret", email: "foo@bar.com", hash: "myAwesomeHash")
//    }
//
//    var httpBody: HTTPBody {
//        return try! HTTPBody(data: JSONEncoder().encode(self))
//    }
//}
//
//struct BugsnagResponseBody<T: Codable>: Codable {
//    struct Event: Codable {
//        struct Request: Codable {
//            let body: T?
//            let headers: [String: String]?
//            let url: String?
//
//            // custom decoding needed as the format is JSON string (not JSON object)
//            init(from decoder: Decoder) throws {
//                let container = try decoder.container(keyedBy: CodingKeys.self)
//                let bodyString = try container.decode(String.self, forKey: .body)
//                guard let data = bodyString.data(using: .utf8) else {
//                    throw Abort(.internalServerError)
//                }
//                body = try JSONDecoder().decode(T.self, from: data)
//                headers = try container.decode(Dictionary.self, forKey: .headers)
//                url = try container.decode(String.self, forKey: .url)
//            }
//        }
//        let request: Request?
//    }
//    let apiKey: String
//    let events: [Event]
//}
