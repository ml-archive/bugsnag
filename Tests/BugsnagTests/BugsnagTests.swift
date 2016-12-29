import XCTest
@testable import BugsnagTests

class BugsnagTests: XCTestCase {
    func test() {
        XCTAssertTrue(true)
    }


    static var allTests : [(String, (BugsnagTests) -> () throws -> Void)] {
        return [
            ("test", test),
        ]
    }
}
