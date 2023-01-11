import MacAppRoute
import Shared
import TypescriptPairQL
import Vapor
import XCore
import XCTest
import XExpect

@testable import Api

final class ApiTests: ApiTestCase {
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testKeyTsCodegen() {
    expect(AppScope.ts).toEqual(
      """
      export type AppScope =
        | { type: 'unrestricted'  }
        | { type: 'webBrowsers'  }
        | { type: 'single'; single: SingleAppScope }
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
    let input = ConnectApp.Input(
      verificationCode: 0,
      appVersion: "1.0.0",
      hostname: nil,
      modelIdentifier: "MacBookPro16,1",
      username: "kids",
      fullUsername: "kids",
      numericId: 501,
      serialNumber: "X02VH0Y6JG5J"
    )

    var request = URLRequest(url: URL(string: "macos-app/ConnectApp")!)
    request.httpMethod = "POST"
    request.httpBody = try JSON.encode(input).data(using: .utf8)

    let expectedRoute = PairQLRoute.macApp(.unauthed(.connectApp(input)))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(expectedRoute)
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
      in: .mock
    )

    expect(response.body.string).toEqual(#"{"status":"active"}"#)
  }

  func testResolveUsersAdminAccountStatus() async throws {
    let user = try await Entities.user(admin: { $0.subscriptionStatus = .active })
    let context = UserContext(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
    let output = try await GetAccountStatus.resolve(in: context)
    expect(output.status).toEqual(.active)
  }
}

extension Context {
  static var mock: Self {
    .init(requestId: "mock-req-id", dashboardUrl: "/")
  }
}
