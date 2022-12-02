import GertieQL
import XCTest

final class RouterTests: XCTestCase {
  typealias Route = GertieQL.Route
  let router = GertieQL.Route.router
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testPost() throws {
    var request = URLRequest(url: URL(string: "macos-app/createSignedScreenshotUpload")!)
    request.setValue(token.uuidString, forHTTPHeaderField: "X-UserToken")

    let missingBody = try? router.match(request: request)
    XCTAssertEqual(missingBody, nil)

    let input = GertieQL.Route.MacApp.UserAuthed.CreateSignedScreenshotUpload.Input(
      width: 100,
      height: 100
    )

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)
    request.httpMethod = "POST"

    let matched = try router.match(request: request)
    let expected = Route.macApp(.userAuthed(token, .createSignedScreenshotUpload(input: input)))
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
    let route = Route.macApp(.userAuthed(token, .getUsersAdminAccountStatus))

    let missingHeader = try? router.match(request: request)
    XCTAssertEqual(missingHeader, nil)

    request.addValue("deadbeef-dead-beef-dead-beefdeadbeef", forHTTPHeaderField: "X-UserToken")
    let matched = try router.match(request: request)
    XCTAssertEqual(matched, route)
  }
}
