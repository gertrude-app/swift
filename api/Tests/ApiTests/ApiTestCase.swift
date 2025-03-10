import Dependencies
import DuetSQL
import FluentPostgresDriver
import Gertie
import Vapor
import XCTest
import XPostmark
import XSlack

@testable import Api

class ApiTestCase: XCTestCase, @unchecked Sendable {
  @Dependency(\.db) var db
  @Dependency(\.env) var env

  nonisolated(unsafe) static var app: Application!
  nonisolated(unsafe) static var migrated = false

  var sent = Sent()
  var app: Application { Self.app }

  override open func invokeTest() {
    withDependencies {
      $0.uuid = UUIDGenerator { UUID() }
      $0.env = .fromProcess(mode: .testing)
      $0.stripe = .failing
      $0.date = .constant(.reference)
      $0.ephemeral = Ephemeral()
      $0.twilio.send = {
        self.sent.texts.append($0)
      }
      $0.slack.send = { @Sendable msg, tok in
        if msg.channel != "debug" {
          self.sent.slacks.append(.init(message: msg, token: tok))
        }
        return nil
      }
      $0.postmark._sendTemplateEmail = { @Sendable email in
        self.sent.emails.append(email)
        return .success(())
      }
      $0.websockets.sendEvent = {
        self.sent.websocketMessages.append($0)
      }
      $0.adminNotifier.notify = {
        self.sent.adminNotifications.append(.init(adminId: $0, event: $1))
      }
      $0.logger = .null
    } operation: {
      super.invokeTest()
    }
  }

  override static func setUp() {
    self.app = Application(.testing)
    self.app.logger = .null
    try! Configure.app(self.app)

    // doing this once per test run gives about a 10x speedup when running all tests
    if !self.migrated {
      // app needs a db for migrations
      Self.app.databases.use(.testDb, as: .psql, isDefault: true)
      try! self.app.autoRevert().wait()
      try! self.app.autoMigrate().wait()
      self.migrated = true
    }
  }

  override static func tearDown() {
    self.app.shutdown()
  }

  func context(_ admin: Admin) -> AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "", admin: admin, ipAddress: nil)
  }

  func context(_ admin: AdminEntities) -> AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "", admin: admin.model, ipAddress: nil)
  }

  func context(_ admin: AdminWithKeychainEntities) -> AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "", admin: admin.model, ipAddress: nil)
  }

  func context(_ user: UserWithDeviceEntities) async throws -> UserContext {
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }

  @discardableResult
  func createAutoIncludeKeychain() async throws -> (Keychain, Api.Key) {
    guard let autoIdStr = self.env.get("AUTO_INCLUDED_KEYCHAIN_ID"),
          let autoId = UUID(uuidString: autoIdStr) else {
      fatalError("need to set AUTO_INCLUDED_KEYCHAIN_ID in api/.env for tests")
    }
    let admin = try await self.admin()
    try await Keychain.query()
      .where(.id == autoId)
      .delete(in: self.db)

    let keychain = try await self.db.create(Keychain(
      id: .init(autoId),
      parentId: admin.model.id,
      name: "Auto Included (test)"
    ))

    let key = try await self.db.create(Key(
      keychainId: keychain.id,
      key: .domain(domain: "foo.com", scope: .webBrowsers)
    ))
    return (keychain, key)
  }
}

extension ApiTestCase {
  struct Sent: Sendable {
    struct AdminNotification: Equatable {
      let adminId: Admin.Id
      let event: AdminEvent
    }

    struct Slack: Equatable, Sendable {
      let message: XSlack.Slack.Message
      let token: String
    }

    var emails: [XPostmark.TemplateEmail] = []
    var slacks: [Slack] = []
    var texts: [Text] = []
    var adminNotifications: [AdminNotification] = []
    var websocketMessages: [AppEvent] = []
  }
}

class DependencyTestCase: XCTestCase {
  override open func invokeTest() {
    withDependencies {
      $0.uuid = UUIDGenerator { UUID() }
      $0.date = .constant(.reference)
    } operation: {
      super.invokeTest()
    }
  }
}

extension UUIDGenerator {
  static func mock(_ uuids: MockUUIDs) -> Self {
    Self { uuids() }
  }
}

struct MockUUIDs: Sendable {
  private var stack: LockIsolated<[UUID]>
  private var copy: LockIsolated<[UUID]>

  var first: UUID { self.copy[0] }
  var second: UUID { self.copy[1] }
  var third: UUID { self.copy[2] }
  var all: [UUID] { self.copy.withValue { $0 } }

  init() {
    let uuids = [UUID(), UUID(), UUID(), UUID(), UUID(), UUID()]
    self.stack = .init(uuids)
    self.copy = .init(uuids)
  }

  func callAsFunction() -> UUID {
    self.stack.withValue { $0.removeFirst() }
  }

  subscript(index: Int) -> UUID {
    self.copy[index]
  }

  func printDebug() {
    self.copy.withValue {
      print("MockUUIDs[0]: \($0[0])")
      print("MockUUIDs[1]: \($0[1])")
      print("MockUUIDs[2]: \($0[2]) [...]")
    }
  }
}

func withUUID<R>(operation: () async throws -> R) async rethrows -> (UUID, R) {
  let uuid = UUID()
  let result = try await withDependencies {
    $0.uuid = UUIDGenerator { uuid }
  } operation: {
    try await operation()
  }
  return (uuid, result)
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}

extension AppEvent {
  init(_ message: WebSocketMessage.FromApiToApp, to matcher: Matcher) {
    self.init(matcher: matcher, message: message)
  }
}

extension XPostmark.TemplateEmail {
  var template: String { self.templateAlias }
}
