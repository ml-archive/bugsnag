import XCTest

import bugsnagTests

var tests = [XCTestCaseEntry]()
tests += BugsnagTests.allTests()
XCTMain(tests)
