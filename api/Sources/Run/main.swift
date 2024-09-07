import Api
import Dependencies
import DuetSQL
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

try withDependencies {
  $0.uuid = UUIDGenerator { UUID() }
  $0.env = .fromProcess(mode: app.environment)
  $0.stripe = .liveValue
  $0.db = PgClient(threadCount: System.coreCount, env: $0.env)
  $0.aws = .liveValue
} operation: {
  try Configure.app(app)
  try app.run()
}
