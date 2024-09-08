import Dependencies
import DuetSQL
import Vapor
import XAws
import XPostmark
import XSendGrid
import XSlack

#if !DEBUG
  struct Environment: Sendable {
    let adminNotifier: AdminNotifier = .live
    let websockets: ConnectedApps = .live
    let ephemeral: Ephemeral = .init()
    var logger: Logger = .null
    var postmark: XPostmark.Client = .mock
    var sendGrid: SendGrid.Client = .mock
    let slack = XSlack.Slack.Client()
    let twilio: TwilioSmsClient = .init()
    let verificationCode: VerificationCodeGenerator = .live
  }
#else
  struct Environment: Sendable {
    var adminNotifier: AdminNotifier = .live
    var websockets: ConnectedApps = .live
    var ephemeral: Ephemeral = .init()
    var logger: Logger = .null
    var postmark: XPostmark.Client = .mock
    var sendGrid: SendGrid.Client = .mock
    var slack = XSlack.Slack.Client()
    var twilio: TwilioSmsClient = .init()
    var verificationCode: VerificationCodeGenerator = .live
  }
#endif

// SAFETY: in non-debug, the mutable members are only
// mutated synchronously during bootstrapping
// before the app starts serving requests
nonisolated(unsafe) var Current = Environment()

#if DEBUG
  extension Environment {
    static let mock = Environment(
      adminNotifier: .mock,
      websockets: .mock,
      ephemeral: .init(),
      logger: .null,
      postmark: .mock,
      sendGrid: .mock,
      slack: .mock,
      twilio: .mock,
      verificationCode: .mock
    )
  }
#endif

struct VerificationCodeGenerator: Sendable {
  var generate: @Sendable () -> Int
  static let live = Self { Int.random(in: 100_000 ... 999_999) }
  static let mock = Self { 0 }
}

extension Date {
  static let mock = Date(timeIntervalSinceReferenceDate: 0)
}

extension UUID {
  static let mock = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
}

func unexpected(_ id: String, detail: String = "") {
  unexpected(id, nil, detail)
}

func unexpected(_ id: String, _ adminId: Admin.Id? = nil, _ detail: String = "") {
  Current.logger.error("Unexpected event `\(id)`, \(detail)")
  Current.sendGrid.fireAndForget(.unexpected(id, detail))
  Task { [detail] in
    @Dependency(\.db) var db
    try await db.create(InterestingEvent(
      eventId: id,
      kind: "event",
      context: "api",
      userDeviceId: nil,
      adminId: adminId,
      detail: detail
    ))
  }
}

func unexpected(_ id: String, _ context: some ResolverContext, _ detail: String = "") {
  var detail = detail
  let adminId: Admin.Id?
  if let adminContext = context as? AdminContext {
    adminId = adminContext.admin.id
    detail += ", admin id: \(adminId!.lowercased)"
  } else {
    adminId = nil
  }
  unexpected(id, adminId, detail)
}
