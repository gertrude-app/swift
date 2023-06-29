import Gertie
import MacAppRoute
import Vapor
import XCore
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class ApiTests: ApiTestCase {
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

  func testDateDecodingInPairQL() async throws {
    let input = SaveKey.Input(
      isNew: true,
      id: .init(),
      keychainId: .init(),
      key: .mock,
      comment: nil,
      expiration: Date(timeIntervalSince1970: 0)
    )
    let admin = try await Entities.admin()
    let token = admin.token.value
    var request = URLRequest(url: URL(string: "dashboard/SaveKey")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601 // <-- without fractional seconds
    request.httpBody = try encoder.encode(input)

    let route = PairQLRoute.dashboard(.adminAuthed(token.rawValue, .saveKey(input)))
    var matched = try? PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)

    // now test that it accepts fractional seconds
    let json = String(data: request.httpBody!, encoding: .utf8)!
    let fractional = json.replacingOccurrences(
      of: "1970-01-01T00:00:00Z",
      with: "1970-01-01T00:00:00.000Z"
    )
    expect(json).not.toBe(fractional)
    request = URLRequest(url: URL(string: "dashboard/SaveKey")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    request.httpBody = fractional.data(using: .utf8)!

    matched = try? PairQLRoute.router.match(request: request)
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
