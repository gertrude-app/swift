import GertieQL
import XCTest

final class RouterTests: XCTestCase {
  typealias Route = GertieQL.XRoute
  let router = GertieQL.router
  let deadbeef = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testPost() throws {
    var request = URLRequest(url: URL(string: "macos-app/createSignedScreenshotUpload")!)
    request.setValue(deadbeef.uuidString, forHTTPHeaderField: "X-UserToken")

    let missingBody = try? router.match(request: request)
    XCTAssertEqual(missingBody, nil)

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(Input(width: 100))
    request.httpMethod = "POST"

    let matched = try router.match(request: request)
    let expected = Route.macApp(.userTokenAuthed(
      deadbeef,
      .createSignedScreenshotUpload(input: .init(width: 100))
    ))
    XCTAssertEqual(matched, expected)
  }

  func testUnauthed() throws {
    var request = URLRequest(url: URL(string: "macos-app/register")!)
    request.httpMethod = "POST"
    let route = Route.macApp(.unauthed(.register))
    let matched = try router.match(request: request)
    XCTAssertEqual(matched, route)
  }

  func testHeaderAuthed() throws {
    var request = URLRequest(url: URL(string: "macos-app/getUsersAdminAccountStatus")!)
    request.httpMethod = "POST"
    let route = Route.macApp(.userTokenAuthed(deadbeef, .getUsersAdminAccountStatus))

    let missingHeader = try? router.match(request: request)
    XCTAssertEqual(missingHeader, nil)

    request.addValue("deadbeef-dead-beef-dead-beefdeadbeef", forHTTPHeaderField: "X-UserToken")
    let matched = try router.match(request: request)
    XCTAssertEqual(matched, route)
  }
}
