import DuetSQL
import Vapor
import XAws
import XPostmark
import XSendGrid
import XSlack
import XStripe

struct Environment {
  var adminNotifier: AdminNotifier = .live
  var aws: AWS.Client = .mock
  var connectedApps: ConnectedApps = .live
  var date: () -> Date = { Date() }
  var db: DuetSQL.Client = ThrowingClient()
  var ephemeral: Ephemeral = .init()
  var env: EnvironmentVariables = .live
  var logger: Logger = .null
  var postmark: XPostmark.Client = .mock
  var sendGrid: SendGrid.Client = .mock
  var slack = XSlack.Slack.Client()
  var stripe: Stripe.Client = .mock
  var twilio: TwilioSmsClient = .init()
  var uuid: () -> UUID = { UUID.new() }
  var verificationCode: VerificationCodeGenerator = .live
}

var Current = Environment()

extension Environment {
  static let mock = Environment(
    adminNotifier: .mock,
    aws: .mock,
    connectedApps: .mock,
    date: { .mock },
    db: ThrowingClient(),
    ephemeral: .init(),
    env: .mock,
    logger: .null,
    postmark: .mock,
    sendGrid: .mock,
    slack: .mock,
    stripe: .mock,
    twilio: .mock,
    uuid: { .mock },
    verificationCode: .mock
  )
}

struct VerificationCodeGenerator {
  var generate: () -> Int
  static let live = Self { Int.random(in: 100_000 ... 999_999) }
  static let mock = Self { 0 }
}

struct EnvironmentVariables {
  var get: (String) -> String?
  static let live = EnvironmentVariables(get: { Env.get($0) })
  static let mock = EnvironmentVariables(get: { _ in nil })
}

extension Date {
  static let mock = Date(timeIntervalSinceReferenceDate: 0)
}

extension UUID {
  static let mock = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
}

func unexpected(_ id: String, _ adminId: Admin.Id? = nil, _ detail: String = "") {
  Current.logger.error("Unexpected event `\(id)`, \(detail)")
  Current.sendGrid.fireAndForget(.unexpected(id, detail))

  Task { [detail] in
    try await Current.db.create(InterestingEvent(
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
