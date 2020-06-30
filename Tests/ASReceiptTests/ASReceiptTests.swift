import XCTest
@testable import ASReceipt
import ASN1Decoder

final class ASReceiptTests: XCTestCase {
    func testParser() {
        let url = Bundle.module.url(forResource: "sandboxReceipt", withExtension: nil)
        XCTAssertNotNil(url!)
        let data = try! Data(contentsOf: url!)
        let pkcs7 = try! ASN1Decoder().decode(PKCS7.self, from: data)
        print(pkcs7)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(ASReceipt().text, "Hello, World!")
    }

    static var allTests = [
        ("testParser", testParser),
    ]
}
