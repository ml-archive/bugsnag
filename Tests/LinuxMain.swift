import XCTest

import bugsnagTests

var tests = [XCTestCaseEntry]()
tests += bugsnagTests.allTests()
XCTMain(tests)