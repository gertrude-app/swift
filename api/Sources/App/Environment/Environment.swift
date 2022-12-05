import DuetSQL
import Vapor

struct Environment {
  var db: DuetSQL.Client = ThrowingClient()
}

var Current = Environment()

extension Environment {
  static let mock = Environment(db: ThrowingClient())
}
