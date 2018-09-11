import XCTest

import BugsnagTests

var tests = [XCTestCaseEntry]()
tests += BugsnagTests.__allTests()

XCTMain(tests)
