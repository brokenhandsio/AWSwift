import XCTest
@testable import AWSwift

class AWSwiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual("Hello, World!", "Hello, World!")
    }


    static var allTests : [(String, (AWSwiftTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
