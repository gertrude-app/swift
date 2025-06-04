import DuetSQL
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

final class ApiTests: ApiTestCase, @unchecked Sendable {
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testDashboardRoute() async throws {
    let admin = try await self.parent()
    let token = admin.token.value
    var request = URLRequest(url: URL(string: "dashboard/GetIdentifiedApps")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    let route = PairQLRoute.dashboard(.adminAuthed(token.rawValue, .getIdentifiedApps))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testDuetDeleteReturnsRealNumDeleted() async throws {
    let m1 = Browser(match: .bundleId("m".random))
    let m2 = Browser(match: .bundleId("m".random))
    try await self.db.create([m1, m2])
    let numDeleted = try await self.db.delete(Browser.self, where: .id |=| [m1.id, m2.id])
    expect(numDeleted).toEqual(2)
  }

  func testDuetEscapesStringsProperly() async throws {
    let admin = try await self.db.create(Admin.random)
    let m = try await self.db.create(Api.SecurityEvent(parentId: admin.id, event: "foo'bar"))
    let retrieved = try await self.db.find(m.id)
    expect(retrieved.event).toEqual("foo'bar")
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
    let admin = try await self.parent()
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
    let input = ConnectUser.Input(
      verificationCode: 0,
      appVersion: "1.0.0",
      modelIdentifier: "MacBookPro16,1",
      username: "kids",
      fullUsername: "kids",
      numericId: 501,
      serialNumber: "X02VH0Y6JG5J"
    )

    var request = URLRequest(url: URL(string: "macos-app/ConnectUser")!)
    request.httpMethod = "POST"
    request.httpBody = try JSON.encode(input).data(using: .utf8)

    let expectedRoute = PairQLRoute.macApp(.unauthed(.connectUser(input)))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(expectedRoute)
  }

  func testHeaderAuthed() throws {
    let input = FilterLogs(bundleIds: [:], events: [:])
    var request = URLRequest(url: URL(string: "macos-app/LogFilterEvents")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)
    let route = PairQLRoute.macApp(.userAuthed(self.token, .logFilterEvents(input)))

    let missingHeader = try? PairQLRoute.router.match(request: request)
    expect(missingHeader).toEqual(nil)

    request.addValue(self.token.uuidString, forHTTPHeaderField: "X-UserToken")

    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testChildContextCreated() async throws {
    let child = try await self.childWithComputer()

    let response = try await PairQLRoute.respond(
      to: .macApp(.userAuthed(
        child.token.value.rawValue,
        .createSuspendFilterRequest_v2(.init(duration: 1, comment: nil))
      )),
      in: .mock
    )

    expect(response.status).toEqual(.ok)
    let uuid = try JSONDecoder().decode(UUID.self, from: response.body.data!)
    let req = try await self.db.find(MacApp.SuspendFilterRequest.Id(uuid))
    let computerUser = try await req.userDevice(in: self.db)
    expect(computerUser.childId).toEqual(child.id)
  }
}

extension Context {
  static var mock: Self {
    .init(requestId: "mock-req-id", dashboardUrl: "/", ipAddress: nil)
  }
}
