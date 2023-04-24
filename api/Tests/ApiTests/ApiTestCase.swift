import DuetSQL
import Vapor
import XCTest
import XPostmark
import XSendGrid
import XSlack

@testable import Api

class ApiTestCase: XCTestCase {
  static var app: Application!

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
    app = Application(.testing)
    try! Configure.app(app)
    app.logger = .null
    try! app.autoRevert().wait()
    try! app.autoMigrate().wait()
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
    app.shutdown()
    sync { await SQL.resetPreparedStatements() }
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
