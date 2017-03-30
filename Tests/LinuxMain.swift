import XCTest
@testable import BugsnagTests

XCTMain([
     testCase(MiddlewareTests.allTests),
     testCase(PayloadTransformerTests.allTests),
     testCase(ReporterTests.allTests)
])
