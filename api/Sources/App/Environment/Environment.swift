import DuetSQL
import Vapor
import XSendGrid

struct Environment {
  var date = { Date() }
  var db: DuetSQL.Client = ThrowingClient()
  var ephemeral = Ephemeral()
  var sendGrid: SendGrid.Client = .mock
  var verificationCode: VerificationCodeGenerator = .live
}

var Current = Environment()

extension Environment {
  static let mock = Environment(
    date: { .mock },
    db: ThrowingClient(),
    ephemeral: Ephemeral(),
    sendGrid: .mock,
    verificationCode: .mock
  )
}

extension Date {
  static let mock = Date(timeIntervalSinceReferenceDate: 0)
}

struct VerificationCodeGenerator {
  var generate: () -> Int

  static let live = Self {
    Int.random(in: 100_000 ... 999_999)
  }

  static let mock = Self {
    0
  }
}
