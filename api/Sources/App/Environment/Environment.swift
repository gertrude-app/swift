import DuetSQL
import Vapor
import XSendGrid
import XStripe

struct Environment {
  var date: () -> Date = { Date() }
  var db: DuetSQL.Client = ThrowingClient()
  var env: EnvironmentVariables = .live
  var ephemeral: Ephemeral = .init()
  var sendGrid: SendGrid.Client = .mock
  var stripe: Stripe.Client = .mock
  var verificationCode: VerificationCodeGenerator = .live
}

var Current = Environment()

extension Environment {
  static let mock = Environment(
    date: { .mock },
    db: ThrowingClient(),
    env: .mock,
    ephemeral: Ephemeral(),
    sendGrid: .mock,
    stripe: .mock,
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
