import MacAppRoute
import Vapor
import XCTest

@testable import App

final class AppTests: AppTestCase {
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testUnauthed() throws {
    var request = URLRequest(url: URL(string: "macos-app/register")!)
    request.httpMethod = "POST"
    let route = PqlRoute.macApp(.unauthed(.register))
    let matched = try PqlRoute.router.match(request: request)
    XCTAssertEqual(matched, route)
  }

  func testHeaderAuthed() throws {
    var request = URLRequest(url: URL(string: "macos-app/GetAccountStatus")!)
    request.httpMethod = "POST"
    let route = PqlRoute.macApp(.userAuthed(token, .getAccountStatus))

    let missingHeader = try? PqlRoute.router.match(request: request)
    XCTAssertEqual(missingHeader, nil)

    request.addValue(token.uuidString, forHTTPHeaderField: "X-UserToken")

    let matched = try PqlRoute.router.match(request: request)
    XCTAssertEqual(matched, route)
  }

  func testUserContextCreated() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })

    let response = try await PqlRoute.respond(
      to: .macApp(.userAuthed(user.token.value.rawValue, .getAccountStatus)),
      in: .init(request: .init())
    )

    XCTAssertEqual(response.body.string, #"{"status":"active"}"#)
  }

  func testResolveUsersAdminAccountStatus() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })
    let output = try await GetAccountStatus.resolve(in: .init(request: .init(), user: user.model))
    XCTAssertEqual(output.status, .active)
  }
}
