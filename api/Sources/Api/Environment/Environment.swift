import DuetSQL
import Vapor
import XSendGrid
import XSlack
import XStripe

struct Environment {
  var aws: AWS = .mock
  var date: () -> Date = { Date() }
  var db: DuetSQL.Client = ThrowingClient()
  var env: EnvironmentVariables = .live
  var ephemeral: Ephemeral = .init()
  var sendGrid: SendGrid.Client = .mock
  var slack = XSlack.Slack.Client()
  var stripe: Stripe.Client = .mock
  var twilio: TwilioSmsClient = .init()
  var verificationCode: VerificationCodeGenerator = .live
  var uuid: () -> UUID = { UUID.new() }
}

var Current = Environment()

extension Environment {
  static let mock = Environment(
    aws: .mock,
    date: { .mock },
    db: ThrowingClient(),
    env: .mock,
    ephemeral: Ephemeral(),
    sendGrid: .mock,
    slack: .mock,
    stripe: .mock,
    twilio: .mock,
    verificationCode: .mock,
    uuid: { .mock }
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
