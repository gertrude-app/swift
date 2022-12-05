import Vapor
import XCTest

@testable import App

final class AppTests: AppTestCase {
  func testUserContextCreated() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })

    let response = try await MacApp.respond(
      to: .userAuthed(user.token.value.rawValue, .getUsersAdminAccountStatus),
      in: .init(request: .init())
    )

    XCTAssertEqual(response.body.string, #"{"status":"active"}"#)
  }

  func testResolveUsersAdminAccountStatus() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })

    let output = try await UserAuthed
      .GetUsersAdminAccountStatus
      .resolve(in: .init(request: .init(), user: user.model))

    XCTAssertEqual(output.status, .active)
  }
}
