import TypeScript
import XCTest

@testable import MenuBar

final class AppCodegen: XCTestCase {
  func testCodegen() throws {
    let codegen = CodeGen()
    let foo = try codegen.declaration(for: MenuBar.State.Screen.self)
    print(foo)
    XCTAssertEqual(false, true)
  }
}
