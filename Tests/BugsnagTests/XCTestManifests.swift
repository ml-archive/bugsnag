import XCTest

extension BugsnagTests {
    static let __allTests = [
        ("testExample", testExample),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BugsnagTests.__allTests),
    ]
}
#endif
