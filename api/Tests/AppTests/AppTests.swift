import MacAppRoute
import XCTest
import XExpect

@testable import App

final class AppTests: AppTestCase {
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testDashboardRoute() async throws {
    let admin = try await Entities.admin()
    let token = admin.token.value
    var request = URLRequest(url: URL(string: "dashboard/GetIdentifiedApps")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    let route = PairQLRoute.dashboard(.adminAuthed(token.rawValue, .getIdentifiedApps))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testUnauthed() throws {
    var request = URLRequest(url: URL(string: "macos-app/register")!)
    request.httpMethod = "POST"
    let route = PairQLRoute.macApp(.unauthed(.register))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testHeaderAuthed() throws {
    var request = URLRequest(url: URL(string: "macos-app/GetAccountStatus")!)
    request.httpMethod = "POST"
    let route = PairQLRoute.macApp(.userAuthed(token, .getAccountStatus))

    let missingHeader = try? PairQLRoute.router.match(request: request)
    expect(missingHeader).toEqual(nil)

    request.addValue(token.uuidString, forHTTPHeaderField: "X-UserToken")

    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testUserContextCreated() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })

    let response = try await PairQLRoute.respond(
      to: .macApp(.userAuthed(user.token.value.rawValue, .getAccountStatus)),
      in: .init(headers: .init())
    )

    expect(response.body.string).toEqual(#"{"status":"active"}"#)
  }

  func testResolveUsersAdminAccountStatus() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })
    let output = try await GetAccountStatus.resolve(in: .init(user: user.model))
    expect(output.status).toEqual(.active)
  }
}
