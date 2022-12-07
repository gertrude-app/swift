import GqlMacOS
import XCTest

final class RouterTests: XCTestCase {
  let router = MacAppRoute.router
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testPost() throws {
    var request = URLRequest(url: URL(string: "createSignedScreenshotUpload")!)
    request.setValue(token.uuidString, forHTTPHeaderField: "X-UserToken")

    let missingBody = try? router.match(request: request)
    XCTAssertEqual(missingBody, nil)

    let input = CreateSignedScreenshotUpload.Input(width: 100, height: 100)

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try router.match(request: request)
    let expected = MacAppRoute.userAuthed(token, .createSignedScreenshotUpload(input: input))
    XCTAssertEqual(matched, expected)
  }

  func testUnauthed() throws {
    let request = URLRequest(url: URL(string: "register")!)
    let route = MacAppRoute.unauthed(.register)
    let matched = try router.match(request: request)
    XCTAssertEqual(matched, route)
  }

  func testHeaderAuthed() throws {
    var request = URLRequest(url: URL(string: "getUsersAdminAccountStatus")!)
    let route = MacAppRoute.userAuthed(token, .getUsersAdminAccountStatus)

    let missingHeader = try? router.match(request: request)
    XCTAssertEqual(missingHeader, nil)

    request.addValue(token.uuidString, forHTTPHeaderField: "X-UserToken")
    let matched = try router.match(request: request)
    XCTAssertEqual(matched, route)
  }
}
