import MacAppRoute
import Shared
import TypescriptPairQL
import XCTest
import XExpect

@testable import App

extension AppScope: TypescriptRepresentable {}
extension AppScope.Single: TypescriptRepresentable {}

final class AppTests: AppTestCase {
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testKeyTsCodegen_isolate() {
    expect(AppScope.ts).toEqual(
      """
      export type __self__ =
        | { type: `unrestricted`  }
        | { type: `webBrowsers`  }
        | {
            type: `single`;
            single:
              | { type: `bundleId` bundleId: string; }
              | { type: `identifiedAppSlug` identifiedAppSlug: string; }
          }
      """
    )
  }

  func testCodableRoundTrippingOfTaggedIds() throws {
    struct WithTagged: TypescriptPairInput {
      let id: User.Id
    }

    let uuid = "A7F4192B-472A-4887-AC54-ED1AE1753AD7"
    let tagged = WithTagged(id: .init(UUID(uuidString: uuid)!))
    let data = try JSONEncoder().encode(tagged)
    var decoded = try JSONDecoder().decode(WithTagged.self, from: data)
    expect(decoded).toEqual(tagged)

    let json = #"{"id":"\#(uuid)"}"#.data(using: .utf8)!
    decoded = try JSONDecoder().decode(WithTagged.self, from: json)
    expect(decoded).toEqual(tagged)
  }

  func testTsCodegenOfTaggedIds() throws {
    struct WithTagged: TypescriptPairInput {
      let id: User.Id
    }

    expect(WithTagged.ts).toEqual(
      """
      export interface __self__ {
        id: UUID;
      }
      """
    )
  }

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
