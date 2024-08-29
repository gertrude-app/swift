import Dependencies
import DuetSQL
import Gertie
import Vapor
import XCTest
import XPostmark
import XSendGrid
import XSlack

@testable import Api

class DependencyTestCase: XCTestCase {
  override open func invokeTest() {
    withDependencies {
      $0.uuid = UUIDGenerator { UUID() }
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

final class MockUUIDs: @unchecked Sendable {
  private let lock = NSLock()
  private var stack: [UUID]
  private var copy: [UUID]

  var first: UUID { self.copy[0] }
  var second: UUID { self.copy[1] }
  var third: UUID { self.copy[2] }
  var all: [UUID] { self.copy }

  init() {
    self.stack = [UUID(), UUID(), UUID(), UUID(), UUID(), UUID()]
    self.copy = self.stack
  }

  func callAsFunction() -> UUID {
    self.lock.lock()
    let uuid = self.stack.removeFirst()
    self.lock.unlock()
    return uuid
  }

  subscript(index: Int) -> UUID {
    self.copy[index]
  }

  func printDebug() {
    for (i, uuid) in self.copy.enumerated() {
      print("MockUUIDs[\(i)]: \(uuid)")
    }
  }
}

class ApiTestCase: DependencyTestCase {
  static var app: Application!
  static var migrated = false

  struct Sent {
    struct AdminNotification: Equatable {
      let adminId: Admin.Id
      let event: AdminEvent
    }

    var emails: [SendGrid.Email] = []
    var postmarkEmails: [XPostmark.Email] = []
    var slacks: [(XSlack.Slack.Message, String)] = []
    var texts: [Text] = []
    var adminNotifications: [AdminNotification] = []
    var websocketMessages: [AppEvent] = []
  }

  var sent = Sent()

  var app: Application {
    Self.app
  }

  override static func setUp() {
    Current = .mock
    self.app = Application(.testing)
    try! Configure.app(self.app)
    self.app.logger = .null
    // doing this once per test run gives about a 10x speedup when running all tests
    if !self.migrated {
      try! self.app.autoRevert().wait()
      try! self.app.autoMigrate().wait()
      self.migrated = true
    }
  }

  override func setUp() {
    Current.sendGrid.send = { [self] email in
      self.sent.emails.append(email)
    }
    Current.postmark.send = { [self] email in
      self.sent.postmarkEmails.append(email)
    }
    Current.slack.send = { @Sendable [self] message, token in
      sent.slacks.append((message, token))
      return nil
    }
    Current.twilio.send = { [self] text in
      sent.texts.append(text)
    }
    Current.adminNotifier.notify = { [self] adminId, event in
      sent.adminNotifications.append(.init(adminId: adminId, event: event))
    }
    Current.websockets.sendEvent = { [self] event in
      sent.websocketMessages.append(event)
    }
  }

  override static func tearDown() {
    self.app.shutdown()
    sync { await SQL.resetPreparedStatements() }
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

  func context(_ user: UserEntities) async throws -> UserContext {
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }

  func context(_ user: UserWithDeviceEntities) async throws -> UserContext {
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }
}

func sync(
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column,
  _ f: @escaping () async throws -> Void
) {
  let exp = XCTestExpectation(description: "sync:\(function):\(line):\(column)")
  Task {
    do {
      try await f()
      exp.fulfill()
    } catch {
      fatalError("Error awaiting \(exp.description) -- \(error)")
    }
  }
  switch XCTWaiter.wait(for: [exp], timeout: 10) {
  case .completed:
    return
  case .timedOut:
    fatalError("Timed out waiting for \(exp.description)")
  default:
    fatalError("Unexpected result waiting for \(exp.description)")
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
