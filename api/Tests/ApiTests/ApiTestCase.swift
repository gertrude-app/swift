import DuetSQL
import Vapor
import XCTest
import XPostmark
import XSendGrid
import XSlack

@testable import Api

class ApiTestCase: XCTestCase {
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
    var appEvents: [AppEvent] = []
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
    Current.slack.send = { [self] message, token in
      sent.slacks.append((message, token))
      return nil
    }
    Current.twilio.send = { [self] text in
      sent.texts.append(text)
    }
    Current.adminNotifier.notify = { [self] adminId, event in
      sent.adminNotifications.append(.init(adminId: adminId, event: event))
    }
    Current.connectedApps.notify = { [self] event in
      sent.appEvents.append(event)
    }
  }

  override static func tearDown() {
    self.app.shutdown()
    sync { await SQL.resetPreparedStatements() }
  }

  func context(_ admin: Admin) -> AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "", admin: admin)
  }

  func context(_ admin: AdminEntities) -> AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "", admin: admin.model)
  }

  func context(_ admin: AdminWithKeychainEntities) -> AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "", admin: admin.model)
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

func mockUUIDs() -> (UUID, UUID) {
  let uuids = (UUID(), UUID())
  var array = [uuids.0, uuids.1]

  UUID.new = {
    guard !array.isEmpty else { return UUID() }
    return array.removeFirst()
  }

  return uuids
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
