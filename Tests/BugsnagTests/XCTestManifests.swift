import XCTest

extension BugsnagTests {
    static let __allTests = [
        ("testMiddleware", testMiddleware),
        ("testReportingCanBeDisabled", testReportingCanBeDisabled),
        ("testSendReport", testSendReport),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BugsnagTests.__allTests),
    ]
}
#endif
